-- Demo records per la tabella segnalazioni (report)
-- Adatta user_id e report_type_id ai valori reali del tuo database
-- Esegui con: mysql -u root -p castellazzo < segnalazioni_demo.sql

INSERT INTO `report` (`user_id`, `report_type_id`, `details`, `address`, `latitude`, `longitude`, `status`, `created_at`, `updated_at`) VALUES
(1, 1, 'Lampione spento in Via Roma 12, zona completamente al buio di notte.', 'Via Roma 12, Castellazzo', 45.415001, 8.887001, 'pending', '2026-04-07 10:30:00', '2026-04-07 10:30:00'),
(1, 2, 'Albero pericolante nel parco centrale, rami sporgenti sulla strada.', 'Parco Centrale, Castellazzo', 45.415200, 8.887300, 'resolved', '2026-03-28 14:15:00', '2026-03-30 09:00:00'),
(1, 3, 'Perdita d\'acqua dal tombino all\'incrocio con Via Mazzini.', 'Via Mazzini, Castellazzo', 45.414800, 8.886500, 'rejected', '2026-03-25 09:00:00', '2026-03-26 11:00:00'),
(1, 4, 'Buca profonda nel marciapiede, rischio caduta per i pedoni.', 'Via Garibaldi 45, Castellazzo', 45.415500, 8.888000, 'pending', '2026-04-01 16:45:00', '2026-04-01 16:45:00');
