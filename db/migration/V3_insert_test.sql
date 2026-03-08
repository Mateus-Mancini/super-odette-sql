BEGIN;

INSERT INTO tipo_usuario (nCdTipoUsuario, cDescricao) VALUES 
(1, 'ALUNO'),
(2, 'PROFESSOR'),
(3, 'SECRETARIA')
ON CONFLICT (nCdTipoUsuario) DO NOTHING;

INSERT INTO usuario (nCdTipoUsuario, cNome, cEmail, cSenha)
VALUES (2, 'Professor Teste', 'professor.teste@institutojef.org.br', '$2a$10$7OzW4cC5FJs9BwSUIK5TPu7l9h5AsjyW.IHboWOhdNRN36jvBXQH6')
ON CONFLICT (cEmail) DO NOTHING;

INSERT INTO professor (nCdUsuario, dtContratacao)
SELECT nCdUsuario, CURRENT_DATE 
FROM usuario WHERE cEmail = 'professor.teste@institutojef.org.br'
ON CONFLICT (nCdUsuario) DO NOTHING;

INSERT INTO usuario (nCdTipoUsuario, cNome, cEmail, cSenha)
VALUES (1, 'Aluno Teste', 'aluno.teste@institutojef.org.br', '$2a$10$7OzW4cC5FJs9BwSUIK5TPu7l9h5AsjyW.IHboWOhdNRN36jvBXQH6')
ON CONFLICT (cEmail) DO NOTHING;

INSERT INTO aluno (nCdUsuario, dtNascimento)
SELECT nCdUsuario, '2010-01-01'
FROM usuario WHERE cEmail = 'aluno.teste@institutojef.org.br'
ON CONFLICT (nCdUsuario) DO NOTHING;

INSERT INTO usuario (nCdTipoUsuario, cNome, cEmail, cSenha)
VALUES (3, 'Secretaria Teste', 'secretaria.teste@institutojef.org.br', '$2a$10$7OzW4cC5FJs9BwSUIK5TPu7l9h5AsjyW.IHboWOhdNRN36jvBXQH6')
ON CONFLICT (cEmail) DO NOTHING;

INSERT INTO secretaria (nCdUsuario)
SELECT nCdUsuario 
FROM usuario WHERE cEmail = 'secretaria.teste@institutojef.org.br'
ON CONFLICT (nCdUsuario) DO NOTHING;

COMMIT;