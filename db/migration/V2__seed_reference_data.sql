INSERT INTO tipo_usuario (nCdTipoUsuario, cDescricao)
VALUES (1, 'ALUNO')
ON CONFLICT (nCdTipoUsuario) DO NOTHING;

INSERT INTO tipo_usuario (nCdTipoUsuario, cDescricao)
VALUES (2, 'PROFESSOR')
ON CONFLICT (nCdTipoUsuario) DO NOTHING;

INSERT INTO tipo_usuario (nCdTipoUsuario, cDescricao)
VALUES (3, 'SECRETARIA')
ON CONFLICT (nCdTipoUsuario) DO NOTHING;