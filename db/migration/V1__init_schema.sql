CREATE TABLE tipo_usuario ( nCdTipoUsuario INTEGER PRIMARY KEY
                           , cDescricao     VARCHAR(50) NOT NULL UNIQUE
                           );

CREATE TABLE usuario ( nCdUsuario     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
                     , nCdTipoUsuario INTEGER      NOT NULL
                     , cNome          VARCHAR(150) NOT NULL
                     , cEmail         VARCHAR(150) NOT NULL UNIQUE
                     , cSenha         VARCHAR(255) NOT NULL
                     , dtCriacao      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                     , dtAtualizacao  TIMESTAMP    NULL
                     , CONSTRAINT fk_usuario_tipo FOREIGN KEY (nCdTipoUsuario) REFERENCES tipo_usuario(nCdTipoUsuario)
                     );

CREATE TABLE aluno ( nCdUsuario   BIGINT PRIMARY KEY
                   , dtNascimento DATE         NULL
                   , CONSTRAINT fk_aluno_usuario FOREIGN KEY (nCdUsuario) REFERENCES usuario(nCdUsuario) ON DELETE CASCADE
                   );

CREATE TABLE professor ( nCdUsuario     BIGINT PRIMARY KEY
                       , dtContratacao  DATE         NULL
                       , CONSTRAINT fk_professor_usuario FOREIGN KEY (nCdUsuario) REFERENCES usuario(nCdUsuario) ON DELETE CASCADE
                       );

CREATE TABLE secretaria ( nCdUsuario    BIGINT PRIMARY KEY
                        , CONSTRAINT fk_secretaria_usuario FOREIGN KEY (nCdUsuario) REFERENCES usuario(nCdUsuario) ON DELETE CASCADE
                        );

CREATE TABLE turma ( nCdTurma BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
                   , cNmTurma VARCHAR(100) NOT NULL
                   , nAno     INTEGER      NOT NULL
                   , CONSTRAINT uq_turma_nome_ano UNIQUE (cNmTurma, nAno)
                   );

CREATE TABLE disciplina ( nCdDisciplina BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
                        , cNmDisciplina VARCHAR(100) NOT NULL UNIQUE
                        );

CREATE TABLE matricula ( nCdMatricula BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
                       , nCdAluno     BIGINT       NOT NULL
                       , nCdTurma     BIGINT       NOT NULL
                       , dtMatricula  DATE         NOT NULL
                       , iStatus      VARCHAR(20)  NOT NULL
                       , CONSTRAINT fk_matricula_aluno FOREIGN KEY (nCdAluno) REFERENCES aluno(nCdUsuario) ON DELETE CASCADE
                       , CONSTRAINT fk_matricula_turma FOREIGN KEY (nCdTurma) REFERENCES turma(nCdTurma) ON DELETE CASCADE
                       , CONSTRAINT uq_matricula UNIQUE (nCdAluno, nCdTurma)
                       );

CREATE TABLE professor_disciplina ( nCdProfessor  BIGINT NOT NULL
                                  , nCdDisciplina BIGINT NOT NULL
                                  , CONSTRAINT pk_professor_disciplina PRIMARY KEY (nCdProfessor, nCdDisciplina)
                                  , CONSTRAINT fk_pd_professor  FOREIGN KEY (nCdProfessor)  REFERENCES professor(nCdUsuario)  ON DELETE CASCADE
                                  , CONSTRAINT fk_pd_disciplina FOREIGN KEY (nCdDisciplina) REFERENCES disciplina(nCdDisciplina) ON DELETE CASCADE
                                  );

CREATE TABLE grade ( nCdGrade      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
                   , nCdTurma      BIGINT  NOT NULL
                   , nCdDisciplina BIGINT  NOT NULL
                   , nCdProfessor  BIGINT  NOT NULL
                   , tHrInicio     TIME    NOT NULL
                   , tHrFim        TIME    NOT NULL
                   , iDiaSemana    INTEGER NOT NULL CHECK (iDiaSemana BETWEEN 1 AND 7)
                   , CONSTRAINT fk_grade_turma      FOREIGN KEY (nCdTurma)      REFERENCES turma(nCdTurma)      ON DELETE CASCADE
                   , CONSTRAINT fk_grade_disciplina FOREIGN KEY (nCdDisciplina) REFERENCES disciplina(nCdDisciplina) ON DELETE CASCADE
                   , CONSTRAINT fk_grade_professor  FOREIGN KEY (nCdProfessor)  REFERENCES professor(nCdUsuario) ON DELETE CASCADE
                   , CONSTRAINT uq_grade UNIQUE ( nCdTurma
                                                 , nCdDisciplina
                                                 , nCdProfessor
                                                 , tHrInicio
                                                 , tHrFim
                                                 , iDiaSemana
                                                 )
                   );

CREATE TABLE nota ( nCdNota       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
                  , nCdAluno      BIGINT       NOT NULL
                  , nCdDisciplina BIGINT       NOT NULL
                  , nValor        DECIMAL(5,2) NOT NULL CHECK (nValor BETWEEN 0 AND 10)
                  , dtLancamento  DATE         NOT NULL
                  , CONSTRAINT fk_nota_aluno      FOREIGN KEY (nCdAluno)      REFERENCES aluno(nCdUsuario)      ON DELETE CASCADE
                  , CONSTRAINT fk_nota_disciplina FOREIGN KEY (nCdDisciplina) REFERENCES disciplina(nCdDisciplina) ON DELETE CASCADE
                  , CONSTRAINT uq_nota UNIQUE (nCdAluno, nCdDisciplina, dtLancamento)
                  );

CREATE TABLE observacao ( nCdObservacao BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
                        , nCdAluno      BIGINT       NOT NULL
                        , cObservacao   VARCHAR(500) NULL
                        , dtRegistro    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
                        , CONSTRAINT fk_observacao_aluno FOREIGN KEY (nCdAluno) REFERENCES aluno(nCdUsuario) ON DELETE CASCADE
                        );