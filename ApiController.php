<?php

namespace App\Controller\Api;

use Doctrine\Persistence\ManagerRegistry;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;
use Symfony\Component\DependencyInjection\ParameterBag\ParameterBagInterface;
use App\Entity\User;
use App\Entity\Report;
use App\Entity\ReportType;
use App\Entity\ReportAttachment;

#[Route('/api')]
class ApiController extends AbstractController
{
    protected $mr;
    protected $params;

    public function __construct(ManagerRegistry $managerRegistry, ParameterBagInterface $params)
    {
        $this->mr = $managerRegistry;
        $this->params = $params;
    }

    private function getAuthenticatedUser(Request $request): ?User
    {
        $token = $request->headers->get('X-AUTH-TOKEN');
        if (!$token) {
            return null;
        }

        $em = $this->mr->getManager();
        return $em->getRepository(User::class)->findOneBy(['apiToken' => $token]);
    }

    private function errorResponse(string $message, int $status = 400): JsonResponse
    {
        return new JsonResponse(['success' => false, 'message' => $message], $status);
    }

    // ==================== AUTH ====================

    #[Route('/login', name: 'api_login', methods: ['POST'])]
    public function login(Request $request, UserPasswordHasherInterface $passwordHasher): JsonResponse
    {
        $data = json_decode($request->getContent(), true);
        $email = $data['email'] ?? '';
        $password = $data['password'] ?? '';

        if (!$email || !$password) {
            return $this->errorResponse('Email e password sono obbligatori.');
        }

        $em = $this->mr->getManager();
        $user = $em->getRepository(User::class)->findOneBy(['email' => $email]);

        if (!$user) {
            return $this->errorResponse('Credenziali non valide.', 401);
        }

        if (!$user->isIsActive() || !$user->isIsAdminActive()) {
            return $this->errorResponse('Account non attivo.', 403);
        }

        if (!$passwordHasher->isPasswordValid($user, $password)) {
            return $this->errorResponse('Credenziali non valide.', 401);
        }

        // Generate API token
        $token = bin2hex(random_bytes(32));
        $user->setApiToken($token);
        $em->flush();

        return new JsonResponse([
            'success' => true,
            'token' => $token,
            'user' => [
                'id' => $user->getId(),
                'email' => $user->getEmail(),
                'name' => $user->getName(),
                'surname' => $user->getSurname(),
                'role' => $user->getRole()
            ]
        ]);
    }

    #[Route('/logout', name: 'api_logout', methods: ['POST'])]
    public function apiLogout(Request $request): JsonResponse
    {
        $user = $this->getAuthenticatedUser($request);
        if (!$user) {
            return $this->errorResponse('Non autenticato.', 401);
        }

        $em = $this->mr->getManager();
        $user->setApiToken(null);
        $em->flush();

        return new JsonResponse(['success' => true, 'message' => 'Logout effettuato.']);
    }

    #[Route('/modifica-password', name: 'api_change_password', methods: ['POST'])]
    public function changePassword(Request $request, UserPasswordHasherInterface $passwordHasher): JsonResponse
    {
        $user = $this->getAuthenticatedUser($request);
        if (!$user) {
            return $this->errorResponse('Non autenticato.', 401);
        }

        $data = json_decode($request->getContent(), true);
        $currentPassword = $data['current_password'] ?? '';
        $newPassword = $data['new_password'] ?? '';

        if (!$currentPassword || !$newPassword) {
            return $this->errorResponse('Password attuale e nuova password sono obbligatorie.');
        }

        if (strlen($newPassword) < 6) {
            return $this->errorResponse('La nuova password deve avere almeno 6 caratteri.');
        }

        if (!$passwordHasher->isPasswordValid($user, $currentPassword)) {
            return $this->errorResponse('La password attuale non è corretta.');
        }

        $em = $this->mr->getManager();
        $hashedPassword = $passwordHasher->hashPassword($user, $newPassword);
        $user->setPassword($hashedPassword);
        $em->flush();

        return new JsonResponse(['success' => true, 'message' => 'Password modificata con successo.']);
    }

    // ==================== REPORT TYPES ====================

    #[Route('/tipi-segnalazione', name: 'api_report_types', methods: ['GET'])]
    public function getReportTypes(Request $request): JsonResponse
    {
        $user = $this->getAuthenticatedUser($request);
        if (!$user) {
            return $this->errorResponse('Non autenticato.', 401);
        }

        $em = $this->mr->getManager();
        $types = $em->getRepository(ReportType::class)->findAllActive();

        $result = [];
        foreach ($types as $type) {
            $result[] = [
                'id' => $type->getId(),
                'name' => $type->getName(),
                'slug' => $type->getSlug(),
                'icon' => $type->getIcon()
            ];
        }

        return new JsonResponse(['success' => true, 'data' => $result]);
    }

    // ==================== REPORTS CRUD ====================

    #[Route('/segnalazioni', name: 'api_reports_list', methods: ['GET'])]
    public function getMyReports(Request $request): JsonResponse
    {
        $user = $this->getAuthenticatedUser($request);
        if (!$user) {
            return $this->errorResponse('Non autenticato.', 401);
        }

        $em = $this->mr->getManager();
        $reports = $em->getRepository(Report::class)->findByUser($user);

        $result = [];
        foreach ($reports as $report) {
            $result[] = $this->serializeReport($report);
        }

        return new JsonResponse(['success' => true, 'data' => $result]);
    }

    #[Route('/segnalazioni/{id}', name: 'api_report_detail', methods: ['GET'])]
    public function getReport(Request $request, string $id): JsonResponse
    {
        $user = $this->getAuthenticatedUser($request);
        if (!$user) {
            return $this->errorResponse('Non autenticato.', 401);
        }

        $em = $this->mr->getManager();
        $report = $em->getRepository(Report::class)->find($id);

        if (!$report || $report->getUser()->getId() !== $user->getId()) {
            return $this->errorResponse('Segnalazione non trovata.', 404);
        }

        return new JsonResponse(['success' => true, 'data' => $this->serializeReport($report, true)]);
    }

    #[Route('/segnalazioni', name: 'api_report_create', methods: ['POST'])]
    public function createReport(Request $request): JsonResponse
    {
        $user = $this->getAuthenticatedUser($request);
        if (!$user) {
            return $this->errorResponse('Non autenticato.', 401);
        }

        $em = $this->mr->getManager();

        $typeId = $request->request->get('type_id');
        $details = $request->request->get('details');
        $latitude = $request->request->get('latitude');
        $longitude = $request->request->get('longitude');
        $address = $request->request->get('address');

        if (!$typeId) {
            return $this->errorResponse('Il tipo di segnalazione è obbligatorio.');
        }

        $reportType = $em->getRepository(ReportType::class)->find($typeId);
        if (!$reportType) {
            return $this->errorResponse('Tipo di segnalazione non valido.');
        }

        $report = new Report();
        $report->setUser($user);
        $report->setReportType($reportType);
        $report->setDatetime(new \DateTime());
        $report->setDetails($details);
        $report->setLatitude($latitude);
        $report->setLongitude($longitude);
        $report->setAddress($address);
        $report->setStatus('pending');
        $report->setPriority(0);

        $em->persist($report);
        $em->flush();

        // Handle file uploads
        $this->handleAttachments($request, $report, $em);

        return new JsonResponse([
            'success' => true,
            'message' => 'Segnalazione inviata con successo.',
            'data' => $this->serializeReport($report)
        ], 201);
    }

    #[Route('/segnalazioni/{id}', name: 'api_report_update', methods: ['POST'])]
    public function updateReport(Request $request, string $id): JsonResponse
    {
        $user = $this->getAuthenticatedUser($request);
        if (!$user) {
            return $this->errorResponse('Non autenticato.', 401);
        }

        $em = $this->mr->getManager();
        $report = $em->getRepository(Report::class)->find($id);

        if (!$report || $report->getUser()->getId() !== $user->getId()) {
            return $this->errorResponse('Segnalazione non trovata.', 404);
        }

        if ($report->getStatus() !== 'pending') {
            return $this->errorResponse('Solo le segnalazioni in attesa possono essere modificate.');
        }

        $typeId = $request->request->get('type_id');
        $details = $request->request->get('details');
        $latitude = $request->request->get('latitude');
        $longitude = $request->request->get('longitude');
        $address = $request->request->get('address');

        if ($typeId) {
            $reportType = $em->getRepository(ReportType::class)->find($typeId);
            if ($reportType) {
                $report->setReportType($reportType);
            }
        }

        if ($details !== null) {
            $report->setDetails($details);
        }
        if ($latitude !== null) {
            $report->setLatitude($latitude);
        }
        if ($longitude !== null) {
            $report->setLongitude($longitude);
        }
        if ($address !== null) {
            $report->setAddress($address);
        }

        // Handle new file uploads
        $this->handleAttachments($request, $report, $em);

        $em->flush();

        return new JsonResponse([
            'success' => true,
            'message' => 'Segnalazione aggiornata.',
            'data' => $this->serializeReport($report)
        ]);
    }

    #[Route('/segnalazioni/{id}/elimina', name: 'api_report_delete', methods: ['POST'])]
    public function deleteReport(Request $request, string $id): JsonResponse
    {
        $user = $this->getAuthenticatedUser($request);
        if (!$user) {
            return $this->errorResponse('Non autenticato.', 401);
        }

        $em = $this->mr->getManager();
        $report = $em->getRepository(Report::class)->find($id);

        if (!$report || $report->getUser()->getId() !== $user->getId()) {
            return $this->errorResponse('Segnalazione non trovata.', 404);
        }

        if ($report->getStatus() !== 'pending') {
            return $this->errorResponse('Solo le segnalazioni in attesa possono essere eliminate.');
        }

        // Remove attachment files
        $uploadDir = $this->params->get('kernel.project_dir').'/'.$this->params->get('web_path').'/uploads/reports/'.$report->getId().'/';
        foreach ($report->getAttachments() as $attachment) {
            $filePath = $uploadDir.$attachment->getFilePath();
            if (file_exists($filePath)) {
                unlink($filePath);
            }
            $em->remove($attachment);
        }

        $em->remove($report);
        $em->flush();

        return new JsonResponse(['success' => true, 'message' => 'Segnalazione eliminata.']);
    }

    // ==================== HELPERS ====================

    private function handleAttachments(Request $request, Report $report, $em): void
    {
        $files = $request->files->get('attachments');
        if (!$files) {
            return;
        }

        if (!is_array($files)) {
            $files = [$files];
        }

        $uploadDir = $this->params->get('kernel.project_dir').'/'.$this->params->get('web_path').'/uploads/reports/'.$report->getId().'/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }

        foreach ($files as $file) {
            if (!$file || !$file->isValid()) {
                continue;
            }

            $originalName = $file->getClientOriginalName();
            $extension = $file->guessExtension() ?? $file->getClientOriginalExtension();
            $fileName = uniqid().'.'.$extension;

            $file->move($uploadDir, $fileName);

            $attachment = new ReportAttachment();
            $attachment->setReport($report);
            $attachment->setFileName($originalName);
            $attachment->setFilePath($fileName);
            $attachment->setFileType($file->getClientMimeType() ?? $extension);
            $attachment->setFileSize(filesize($uploadDir.$fileName));
            $attachment->setUploadedAt(new \DateTime());

            $em->persist($attachment);
        }

        $em->flush();
    }

    private function serializeReport(Report $report, bool $includeAttachments = false): array
    {
        $data = [
            'id' => $report->getId(),
            'type' => [
                'id' => $report->getReportType()->getId(),
                'name' => $report->getReportType()->getName(),
                'slug' => $report->getReportType()->getSlug()
            ],
            'datetime' => $report->getDatetime()->format('Y-m-d H:i:s'),
            'latitude' => $report->getLatitude(),
            'longitude' => $report->getLongitude(),
            'address' => $report->getAddress(),
            'priority' => $report->getPriority(),
            'details' => $report->getDetails(),
            'status' => $report->getStatus(),
            'status_label' => $report->getStatusLabel()
        ];

        if ($includeAttachments) {
            $attachments = [];
            foreach ($report->getAttachments() as $att) {
                $attachments[] = [
                    'id' => $att->getId(),
                    'file_name' => $att->getFileName(),
                    'file_path' => '/uploads/reports/'.$report->getId().'/'.$att->getFilePath(),
                    'file_type' => $att->getFileType(),
                    'uploaded_at' => $att->getUploadedAt()->format('Y-m-d H:i:s')
                ];
            }
            $data['attachments'] = $attachments;
        }

        return $data;
    }
}
