SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS alexandria_db;
CREATE DATABASE alexandria_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE alexandria_db;
SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE niveis (
  id           TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome         VARCHAR(30)  NOT NULL,         
  icone        VARCHAR(10)  NOT NULL,           
  pontos_min   INT UNSIGNED NOT NULL,
  pontos_max   INT UNSIGNED,                    
  descricao    VARCHAR(255),
  CONSTRAINT uq_nivel_nome UNIQUE (nome)
) COMMENT 'Níveis do sistema de gamificação';

INSERT INTO niveis (nome, icone, pontos_min, pontos_max, descricao) VALUES
  ('Iniciante',    '📖', 0,    499,  'Pode pesquisar materiais, ver resumos e salvar favoritos'),
  ('Colaborador',  '🏛️', 500,  1999, 'Pode enviar TCCs, dar feedback e corrigir resumos'),
  ('Especialista', '⭐', 2000, 4999, 'Pode curar materiais, tem badge no perfil e acesso antecipado'),
  ('Mestre',       '🔱', 5000, NULL, 'Nível máximo — acesso completo e reconhecimento da comunidade');


CREATE TABLE cursos (
  id    SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome  VARCHAR(100) NOT NULL,
  sigla VARCHAR(10),
  CONSTRAINT uq_curso_nome UNIQUE (nome)
) COMMENT 'Cursos da instituição';

INSERT INTO cursos (nome, sigla) VALUES
  ('Desenvolvimento de Software Multiplataforma', 'DSM'),
  ('Gestão Empresarial',                          'GE'),
  ('Logística',                                   'LOG'),
  ('Ciência da Computação',                       'CC'),
  ('Engenharia de Software',                      'ES'),
  ('Sistemas de Informação',                      'SI'),
  ('Análise e Desenvolvimento de Sistemas',       'ADS');


CREATE TABLE usuarios (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome            VARCHAR(150) NOT NULL,
  email           VARCHAR(254) NOT NULL,
  senha_hash      VARCHAR(255) NOT NULL,           
  curso_id        SMALLINT UNSIGNED,
  semestre        TINYINT UNSIGNED,                
  pontos          INT UNSIGNED NOT NULL DEFAULT 0,
  nivel_id        TINYINT UNSIGNED NOT NULL DEFAULT 1,
  avatar_inicial  CHAR(2),                        
  ativo           BOOLEAN NOT NULL DEFAULT TRUE,
  email_verificado BOOLEAN NOT NULL DEFAULT FALSE,
  criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_usuario_email UNIQUE (email),
  CONSTRAINT fk_usuario_curso  FOREIGN KEY (curso_id)  REFERENCES cursos(id)  ON DELETE SET NULL,
  CONSTRAINT fk_usuario_nivel  FOREIGN KEY (nivel_id)  REFERENCES niveis(id)  ON UPDATE CASCADE
) COMMENT 'Usuários da plataforma — alunos e colaboradores';

CREATE INDEX idx_usuarios_pontos   ON usuarios(pontos);
CREATE INDEX idx_usuarios_nivel    ON usuarios(nivel_id);
CREATE INDEX idx_usuarios_curso    ON usuarios(curso_id);


CREATE TABLE sessoes (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id   INT UNSIGNED NOT NULL,
  token_hash   VARCHAR(255) NOT NULL,              
  ip           VARCHAR(45),                          
  user_agent   VARCHAR(500),
  expira_em    DATETIME NOT NULL,
  criado_em    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sessao_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) COMMENT 'Sessões ativas — refresh tokens';

CREATE INDEX idx_sessoes_usuario  ON sessoes(usuario_id);
CREATE INDEX idx_sessoes_token    ON sessoes(token_hash);
CREATE INDEX idx_sessoes_expira   ON sessoes(expira_em);


CREATE TABLE materiais (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  titulo          VARCHAR(500)  NOT NULL,
  tipo            ENUM('tcc','livro','artigo') NOT NULL,
  autor           VARCHAR(300)  NOT NULL,
  curso_id        SMALLINT UNSIGNED,
  area            VARCHAR(100),                     
  ano             YEAR,
  resumo_manual   TEXT,                              
  link_externo    VARCHAR(2083),                     
  arquivo_path    VARCHAR(500),                      
  indexado_rag    BOOLEAN NOT NULL DEFAULT FALSE,   
  publicado       BOOLEAN NOT NULL DEFAULT TRUE,
  visualizacoes   INT UNSIGNED NOT NULL DEFAULT 0,
  enviado_por     INT UNSIGNED,                      
  aprovado_por    INT UNSIGNED,                      
  criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_material_curso      FOREIGN KEY (curso_id)    REFERENCES cursos(id)   ON DELETE SET NULL,
  CONSTRAINT fk_material_enviado    FOREIGN KEY (enviado_por) REFERENCES usuarios(id) ON DELETE SET NULL,
  CONSTRAINT fk_material_aprovado   FOREIGN KEY (aprovado_por) REFERENCES usuarios(id) ON DELETE SET NULL
) COMMENT 'Materiais acadêmicos — TCCs, livros e artigos indexados';

CREATE FULLTEXT INDEX ft_materiais_titulo  ON materiais(titulo);
CREATE FULLTEXT INDEX ft_materiais_autor   ON materiais(autor);
CREATE INDEX idx_materiais_tipo            ON materiais(tipo);
CREATE INDEX idx_materiais_ano             ON materiais(ano);
CREATE INDEX idx_materiais_curso           ON materiais(curso_id);
CREATE INDEX idx_materiais_indexado        ON materiais(indexado_rag);


CREATE TABLE chunks_rag (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  material_id     INT UNSIGNED NOT NULL,
  numero_chunk    SMALLINT UNSIGNED NOT NULL,        
  conteudo        TEXT NOT NULL,                    
  chroma_id       VARCHAR(100),                      
  pagina          SMALLINT UNSIGNED,                 
  tokens          SMALLINT UNSIGNED,                 
  criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_chunk_material FOREIGN KEY (material_id) REFERENCES materiais(id) ON DELETE CASCADE,
  CONSTRAINT uq_chunk_material_numero UNIQUE (material_id, numero_chunk)
) COMMENT 'Metadados dos chunks gerados pelo pipeline RAG';

CREATE INDEX idx_chunks_material  ON chunks_rag(material_id);
CREATE INDEX idx_chunks_chroma    ON chunks_rag(chroma_id);


CREATE TABLE resumos (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id      INT UNSIGNED NOT NULL,
  query_original  VARCHAR(1000) NOT NULL,            
  titulo          VARCHAR(500),                      
  conteudo        LONGTEXT NOT NULL,                 
  modelo_ia       VARCHAR(50) NOT NULL DEFAULT 'gpt-4o-mini',
  tokens_usados   INT UNSIGNED,
  tempo_ms        INT UNSIGNED,                      
  nota_usuario    TINYINT UNSIGNED,                  
  criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_resumo_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) COMMENT 'Resumos gerados pelo pipeline RAG';

CREATE INDEX idx_resumos_usuario   ON resumos(usuario_id);
CREATE INDEX idx_resumos_criado    ON resumos(criado_em);
CREATE FULLTEXT INDEX ft_resumos_query ON resumos(query_original, titulo);

CREATE TABLE resumo_fontes (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  resumo_id       INT UNSIGNED NOT NULL,
  chunk_id        BIGINT UNSIGNED NOT NULL,
  similaridade    DECIMAL(5,4) NOT NULL,             
  trecho_usado    TEXT,                              
  CONSTRAINT fk_fonte_resumo  FOREIGN KEY (resumo_id) REFERENCES resumos(id)    ON DELETE CASCADE,
  CONSTRAINT fk_fonte_chunk   FOREIGN KEY (chunk_id)  REFERENCES chunks_rag(id) ON DELETE CASCADE
) COMMENT 'Rastreabilidade: quais chunks foram usados em cada resumo';

CREATE INDEX idx_fonte_resumo  ON resumo_fontes(resumo_id);
CREATE INDEX idx_fonte_chunk   ON resumo_fontes(chunk_id);


CREATE TABLE chat_mensagens (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  resumo_id   INT UNSIGNED NOT NULL,
  usuario_id  INT UNSIGNED NOT NULL,
  role        ENUM('user', 'assistant') NOT NULL,
  conteudo    TEXT NOT NULL,
  tokens      SMALLINT UNSIGNED,
  criado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_chat_resumo  FOREIGN KEY (resumo_id)  REFERENCES resumos(id)   ON DELETE CASCADE,
  CONSTRAINT fk_chat_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) COMMENT 'Histórico do chat contextual por resumo';

CREATE INDEX idx_chat_resumo   ON chat_mensagens(resumo_id);
CREATE INDEX idx_chat_usuario  ON chat_mensagens(usuario_id);
CREATE INDEX idx_chat_criado   ON chat_mensagens(criado_em);


CREATE TABLE feedbacks (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  resumo_id   INT UNSIGNED NOT NULL,
  usuario_id  INT UNSIGNED NOT NULL,
  tipo        ENUM('util','faltou_informacao','confuso','incorreto') NOT NULL,
  comentario  TEXT,
  resolvido   BOOLEAN NOT NULL DEFAULT FALSE,
  criado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_feedback_resumo  FOREIGN KEY (resumo_id)  REFERENCES resumos(id)   ON DELETE CASCADE,
  CONSTRAINT fk_feedback_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  CONSTRAINT uq_feedback_por_resumo UNIQUE (resumo_id, usuario_id)  -- 1 feedback por usuário por resumo
) COMMENT 'Feedback qualitativo dos usuários sobre cada resumo';

CREATE INDEX idx_feedback_resumo   ON feedbacks(resumo_id);
CREATE INDEX idx_feedback_usuario  ON feedbacks(usuario_id);
CREATE INDEX idx_feedback_tipo     ON feedbacks(tipo);


CREATE TABLE favoritos (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id   INT UNSIGNED NOT NULL,
  material_id  INT UNSIGNED,                        -- material favoritado
  resumo_id    INT UNSIGNED,                        -- ou resumo favoritado
  anotacao     TEXT,                                -- nota pessoal do aluno
  criado_em    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_fav_usuario  FOREIGN KEY (usuario_id)  REFERENCES usuarios(id)  ON DELETE CASCADE,
  CONSTRAINT fk_fav_material FOREIGN KEY (material_id) REFERENCES materiais(id) ON DELETE CASCADE,
  CONSTRAINT fk_fav_resumo   FOREIGN KEY (resumo_id)   REFERENCES resumos(id)   ON DELETE CASCADE,
  
  CONSTRAINT chk_favorito_alvo CHECK (
    (material_id IS NOT NULL AND resumo_id IS NULL) OR
    (material_id IS NULL AND resumo_id IS NOT NULL)
  )
) COMMENT 'Materiais e resumos salvos pelo usuário';

CREATE INDEX idx_fav_usuario   ON favoritos(usuario_id);
CREATE INDEX idx_fav_material  ON favoritos(material_id);
CREATE INDEX idx_fav_resumo    ON favoritos(resumo_id);

CREATE TABLE conquistas (
  id                  SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome                VARCHAR(80)  NOT NULL,
  descricao           VARCHAR(300) NOT NULL,
  icone               VARCHAR(10),                   
  tipo                ENUM(
                        'tcc_enviado',
                        'resumo_gerado',
                        'feedback_dado',
                        'contribuicao',
                        'nivel_alcancado',
                        'primeiro_acesso',
                        'streak'
                      ) NOT NULL,
  meta                INT UNSIGNED NOT NULL DEFAULT 1,  
  pontos_bonus        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  CONSTRAINT uq_conquista_nome UNIQUE (nome)
) COMMENT 'Conquistas desbloqueáveis por ações na plataforma';

INSERT INTO conquistas (nome, descricao, icone, tipo, meta, pontos_bonus) VALUES
  ('Primeiro Passo',        'Fez login pela primeira vez',                          '🚀', 'primeiro_acesso',  1,   50),
  ('Pesquisador',           'Gerou seu primeiro resumo com IA',                     '🔍', 'resumo_gerado',     1,   30),
  ('Contribuidor',          'Enviou seu primeiro TCC ao repositório',               '📤', 'tcc_enviado',       1,  200),
  ('Crítico Construtivo',   'Deu 5 feedbacks de qualidade',                         '✏️', 'feedback_dado',     5,   50),
  ('Bom Samaritano',        'Deu 20 feedbacks de qualidade',                        '💡', 'feedback_dado',    20,  100),
  ('Especialista Nível 3',  'Alcançou o nível Especialista',                        '⭐', 'nivel_alcancado',   3,  300),
  ('Mestre do Conhecimento','Alcançou o nível Mestre',                              '🔱', 'nivel_alcancado',   4,  500),
  ('Colecionador',          'Salvou 10 resumos nos favoritos',                      '📚', 'contribuicao',     10,   50),
  ('Acervo Vivo',           'Enviou 5 TCCs ao repositório',                         '🏛️', 'tcc_enviado',       5,  400),
  ('Gerador de Valor',      'Gerou 50 resumos com IA',                             '🧠', 'resumo_gerado',    50,  150);


CREATE TABLE usuario_conquistas (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id      INT UNSIGNED NOT NULL,
  conquista_id    SMALLINT UNSIGNED NOT NULL,
  desbloqueado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_usuario_conquista UNIQUE (usuario_id, conquista_id),
  CONSTRAINT fk_uc_usuario    FOREIGN KEY (usuario_id)   REFERENCES usuarios(id)   ON DELETE CASCADE,
  CONSTRAINT fk_uc_conquista  FOREIGN KEY (conquista_id) REFERENCES conquistas(id) ON DELETE CASCADE
) COMMENT 'Relacionamento usuário <-> conquistas desbloqueadas';

CREATE INDEX idx_uc_usuario    ON usuario_conquistas(usuario_id);
CREATE INDEX idx_uc_conquista  ON usuario_conquistas(conquista_id);

CREATE TABLE pontos_historico (
  id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id   INT UNSIGNED NOT NULL,
  quantidade   SMALLINT NOT NULL,                    
  motivo       ENUM(
                 'cadastro',
                 'resumo_gerado',
                 'tcc_enviado',
                 'feedback_dado',
                 'correcao_aceita',
                 'conquista_desbloqueada',
                 'material_curtido',
                 'bonus_admin',
                 'ajuste'
               ) NOT NULL,
  referencia_id INT UNSIGNED,                        
  descricao    VARCHAR(200),
  criado_em    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pts_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) COMMENT 'Log auditável de todas as transações de pontos';

CREATE INDEX idx_pts_usuario  ON pontos_historico(usuario_id);
CREATE INDEX idx_pts_motivo   ON pontos_historico(motivo);
CREATE INDEX idx_pts_criado   ON pontos_historico(criado_em);

CREATE TABLE atividades (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id      INT UNSIGNED NOT NULL,
  tipo            ENUM(
                    'tcc_enviado',
                    'resumo_gerado',
                    'feedback_dado',
                    'correcao_feita',
                    'conquista_desbloqueada',
                    'nivel_subiu',
                    'comentou'
                  ) NOT NULL,
  descricao       VARCHAR(500) NOT NULL,              
  referencia_tipo VARCHAR(30),                        
  referencia_id   INT UNSIGNED,                       
  publica         BOOLEAN NOT NULL DEFAULT TRUE,
  criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ativ_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) COMMENT 'Feed público de atividades para a página Comunidade';

CREATE INDEX idx_ativ_usuario  ON atividades(usuario_id);
CREATE INDEX idx_ativ_tipo     ON atividades(tipo);
CREATE INDEX idx_ativ_criado   ON atividades(criado_em);
CREATE INDEX idx_ativ_publica  ON atividades(publica);


CREATE TABLE buscas (
  id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id   INT UNSIGNED,                          
  termo        VARCHAR(500) NOT NULL,
  resultados   SMALLINT UNSIGNED,
  criado_em    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_busca_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
) COMMENT 'Log de todas as buscas realizadas na plataforma';

CREATE INDEX idx_busca_usuario  ON buscas(usuario_id);
CREATE INDEX idx_busca_criado   ON buscas(criado_em);
CREATE FULLTEXT INDEX ft_busca_termo ON buscas(termo);


CREATE TABLE comentarios (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id   INT UNSIGNED NOT NULL,
  material_id  INT UNSIGNED,
  resumo_id    INT UNSIGNED,
  conteudo     TEXT NOT NULL,
  aprovado     BOOLEAN NOT NULL DEFAULT TRUE,
  criado_em    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_coment_usuario  FOREIGN KEY (usuario_id)  REFERENCES usuarios(id)  ON DELETE CASCADE,
  CONSTRAINT fk_coment_material FOREIGN KEY (material_id) REFERENCES materiais(id) ON DELETE CASCADE,
  CONSTRAINT fk_coment_resumo   FOREIGN KEY (resumo_id)   REFERENCES resumos(id)   ON DELETE CASCADE,
  CONSTRAINT chk_coment_alvo CHECK (
    (material_id IS NOT NULL AND resumo_id IS NULL) OR
    (material_id IS NULL AND resumo_id IS NOT NULL)
  )
) COMMENT 'Comentários e correções em materiais e resumos';

CREATE INDEX idx_coment_usuario   ON comentarios(usuario_id);
CREATE INDEX idx_coment_material  ON comentarios(material_id);
CREATE INDEX idx_coment_resumo    ON comentarios(resumo_id);


CREATE TRIGGER trg_atualiza_pontos_nivel
AFTER INSERT ON pontos_historico
FOR EACH ROW
BEGIN
  DECLARE novo_total INT UNSIGNED;
  DECLARE novo_nivel TINYINT UNSIGNED;

  SELECT GREATEST(0, SUM(quantidade))
    INTO novo_total
    FROM pontos_historico
   WHERE usuario_id = NEW.usuario_id;

  SELECT id INTO novo_nivel
    FROM niveis
   WHERE pontos_min <= novo_total
     AND (pontos_max IS NULL OR pontos_max >= novo_total)
   ORDER BY pontos_min DESC
   LIMIT 1;

  UPDATE usuarios
     SET pontos   = novo_total,
         nivel_id = novo_nivel
   WHERE id = NEW.usuario_id;
END$$


CREATE TRIGGER trg_resumo_gerado
AFTER INSERT ON resumos
FOR EACH ROW
BEGIN
  INSERT INTO pontos_historico (usuario_id, quantidade, motivo, referencia_id, descricao)
    VALUES (NEW.usuario_id, 30, 'resumo_gerado', NEW.id, CONCAT('Resumo gerado: ', LEFT(NEW.query_original, 80)));

  INSERT INTO atividades (usuario_id, tipo, descricao, referencia_tipo, referencia_id)
    VALUES (NEW.usuario_id, 'resumo_gerado',
            CONCAT('Gerou um resumo sobre "', LEFT(NEW.query_original, 100), '"'),
            'resumo', NEW.id);
END$$

CREATE TRIGGER trg_material_enviado
AFTER INSERT ON materiais
FOR EACH ROW
BEGIN
  IF NEW.enviado_por IS NOT NULL THEN
    INSERT INTO pontos_historico (usuario_id, quantidade, motivo, referencia_id, descricao)
      VALUES (NEW.enviado_por, 200, 'tcc_enviado', NEW.id,
              CONCAT('Material enviado: ', LEFT(NEW.titulo, 80)));

    INSERT INTO atividades (usuario_id, tipo, descricao, referencia_tipo, referencia_id)
      VALUES (NEW.enviado_por, 'tcc_enviado',
              CONCAT('Enviou o material "', LEFT(NEW.titulo, 120), '"'),
              'material', NEW.id);
  END IF;
END$$

CREATE TRIGGER trg_feedback_dado
AFTER INSERT ON feedbacks
FOR EACH ROW
BEGIN
  INSERT INTO pontos_historico (usuario_id, quantidade, motivo, referencia_id, descricao)
    VALUES (NEW.usuario_id, 30, 'feedback_dado', NEW.resumo_id,
            CONCAT('Feedback dado — tipo: ', NEW.tipo));

  INSERT INTO atividades (usuario_id, tipo, descricao, referencia_tipo, referencia_id)
    VALUES (NEW.usuario_id, 'feedback_dado',
            'Contribuiu com um feedback de qualidade em um resumo',
            'resumo', NEW.resumo_id);
END$$

DELIMITER ;


INSERT INTO usuarios (nome, email, senha_hash, curso_id, semestre, pontos, nivel_id, avatar_inicial) VALUES
  ('Michelle Kaolin Souza', 'michelle@fatec.sp.gov.br',
   '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBMm2S3kF9XKPK',
   1, 6, 1250, 3, 'MS'),
  ('João Silva',            'joao@fatec.sp.gov.br',
   '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBMm2S3kF9XKPK',
   1, 4, 1240, 2, 'JS'),
  ('Ana Clara Souza',       'ana@fatec.sp.gov.br',
   '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBMm2S3kF9XKPK',
   4, 8,  820, 2, 'AS'),
  ('Carlos Lima',           'carlos@fatec.sp.gov.br',
   '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBMm2S3kF9XKPK',
   5, 7,  450, 1, 'CL');


INSERT INTO materiais (titulo, tipo, autor, curso_id, area, ano, publicado, indexado_rag, enviado_por) VALUES
  ('Sistema de Monitoramento com Drones para Fire Prevention',
   'tcc', 'Michelle Kaolin Souza', 1, 'Tecnologia', 2025, TRUE, TRUE, 1),

  ('Análise de Sentimentos em Fragrâncias e Emoções',
   'artigo', 'Helena & Maduh', 1, 'Inovação', 2026, TRUE, TRUE, NULL),

  ('Otimização de Filas em Cafetarias Digitais (Cantec)',
   'tcc', 'Grupo Genius', 1, 'UX/UI', 2026, TRUE, FALSE, NULL),

  ('Normalização e Dependências Funcionais em Banco de Dados',
   'tcc', 'Ana Souza', 4, 'Banco de Dados', 2023, TRUE, TRUE, 3),

  ('Flutter vs React Native: Análise Comparativa de Performance',
   'tcc', 'Ana Clara Souza', 4, 'Mobile', 2024, TRUE, TRUE, 3),

  ('Fundamentos de Banco de Dados',
   'livro', 'Abraham Silberschatz', NULL, 'Banco de Dados', 2019, TRUE, TRUE, NULL),

  ('Segurança em APIs REST com OAuth 2.0',
   'artigo', 'Marta Ferreira', 6, 'Segurança', 2022, TRUE, TRUE, NULL),

  ('Implementação de Normalização em Sistemas Multiplataforma',
   'tcc', 'Michelle Kaolin Souza', 1, 'Banco de Dados', 2026, TRUE, TRUE, 1);


INSERT INTO resumos (usuario_id, query_original, titulo, conteudo, modelo_ia, tokens_usados, tempo_ms)
VALUES (
  2,
  'Explique normalização 3FN em banco de dados',
  'Normalização: Terceira Forma Normal (3FN)',
  'A Terceira Forma Normal (3FN) é um estágio crucial no design de bancos de dados relacionais. Uma tabela está na 3FN se estiver na 2FN e todos os seus atributos não-chave forem independentes entre si — eliminando dependências transitivas.',
  'gpt-4o-mini',
  420,
  1840
);


INSERT INTO atividades (usuario_id, tipo, descricao, referencia_tipo, referencia_id, criado_em) VALUES
  (1, 'tcc_enviado',    'Enviou um novo TCC sobre "Monitoramento com Drones em Osasco"', 'material', 1, NOW() - INTERVAL 2 DAY),
  (2, 'correcao_feita', 'Corrigiu uma citação no resumo de Banco de Dados',               'resumo',   1, NOW() - INTERVAL 1 DAY),
  (3, 'tcc_enviado',    'Enviou o TCC "Flutter vs React Native"',                         'material', 5, NOW() - INTERVAL 3 DAY);


INSERT INTO pontos_historico (usuario_id, quantidade, motivo, descricao, criado_em) VALUES
  (1, 50,  'cadastro',       'Criação de conta',            NOW() - INTERVAL 90 DAY),
  (1, 200, 'tcc_enviado',    'TCC Drones enviado',          NOW() - INTERVAL 60 DAY),
  (1, 200, 'tcc_enviado',    'TCC Normalização enviado',    NOW() - INTERVAL 30 DAY),
  (1, 800, 'bonus_admin',    'Pontos de migração de sistema',NOW() - INTERVAL 20 DAY),
  (2, 50,  'cadastro',       'Criação de conta',            NOW() - INTERVAL 80 DAY),
  (2, 30,  'feedback_dado',  'Feedback no resumo #1',       NOW() - INTERVAL 5 DAY),
  (2, 30,  'resumo_gerado',  'Resumo 3FN gerado',           NOW() - INTERVAL 1 DAY);


INSERT INTO usuario_conquistas (usuario_id, conquista_id) VALUES
  (1, 1), (1, 3), (1, 6), (1, 9),  
  (2, 1), (2, 2);                   


CREATE VIEW vw_perfil_usuario AS
SELECT
  u.id,
  u.nome,
  u.email,
  u.pontos,
  u.nivel_id,
  n.nome              AS nivel_nome,
  n.icone             AS nivel_icone,
  n.pontos_min,
  n.pontos_max,
  ROUND(
    CASE
      WHEN n.pontos_max IS NULL THEN 100
      ELSE (u.pontos - n.pontos_min) * 100.0 / (n.pontos_max - n.pontos_min)
    END, 1
  )                   AS nivel_progresso_pct,
  c.nome              AS curso_nome,
  u.semestre,
  u.avatar_inicial,
  u.criado_em,
  (SELECT COUNT(*) FROM materiais  WHERE enviado_por  = u.id)            AS total_tccs,
  (SELECT COUNT(*) FROM resumos    WHERE usuario_id   = u.id)            AS total_resumos,
  (SELECT COUNT(*) FROM feedbacks  WHERE usuario_id   = u.id)            AS total_feedbacks,
  (SELECT COUNT(*) FROM favoritos  WHERE usuario_id   = u.id)            AS total_favoritos
FROM usuarios u
JOIN niveis n  ON n.id = u.nivel_id
LEFT JOIN cursos c ON c.id = u.curso_id;


CREATE VIEW vw_ranking AS
SELECT
  u.id,
  u.nome,
  u.pontos,
  u.avatar_inicial,
  n.nome  AS nivel,
  n.icone AS nivel_icone,
  c.sigla AS curso_sigla,
  RANK() OVER (ORDER BY u.pontos DESC) AS posicao
FROM usuarios u
JOIN niveis n  ON n.id = u.nivel_id
LEFT JOIN cursos c ON c.id = u.curso_id
WHERE u.ativo = TRUE;


CREATE VIEW vw_feed_comunidade AS
SELECT
  a.id,
  a.tipo,
  a.descricao,
  a.referencia_tipo,
  a.referencia_id,
  a.criado_em,
  u.id            AS usuario_id,
  u.nome          AS usuario_nome,
  u.avatar_inicial,
  n.nome          AS nivel_nome,
  n.icone         AS nivel_icone
FROM atividades a
JOIN usuarios u ON u.id = a.usuario_id
JOIN niveis   n ON n.id = u.nivel_id
WHERE a.publica = TRUE
ORDER BY a.criado_em DESC;

CREATE VIEW vw_materiais_listagem AS
SELECT
  m.id,
  m.titulo,
  m.tipo,
  m.autor,
  m.area,
  m.ano,
  m.visualizacoes,
  m.indexado_rag,
  c.nome  AS curso_nome,
  c.sigla AS curso_sigla,
  u.nome  AS enviado_por_nome
FROM materiais m
LEFT JOIN cursos   c ON c.id = m.curso_id
LEFT JOIN usuarios u ON u.id = m.enviado_por
WHERE m.publicado = TRUE;
SET FOREIGN KEY CHECKS = 0;
DROP DATABASE IF EXISTS alexandria_db;
CREATE DATABASE alexandria_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE alexandria_db;
SET FOREIGN KEY CHECKS = 1;

CREATE TABLE niveis (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(30) NOT NULL,
    icone VARCHAR(10) NOT NULL,
    pontos_min INT UNSIGNED NOT NULL,
    pontos_max INT UNSIGNED,
    CONSTRAINT uq_nivel_nome UNIQUE (nome)
);

INSERT INTO niveis (nome, icone, pontos_min, pontos_max) VALUES
('Iniciante', '🥉', 0, 499),
('Colaborador', '🥈', 500, 1999),
('Especialista', '🥇', 2000, 4999),
('Mestre', '💎', 5000, NULL);

CREATE TABLE cursos (
    id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    sigla VARCHAR(10)
);

CREATE TABLE usuarios (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    curso_id SMALLINT UNSIGNED,
    nivel_id TINYINT UNSIGNED DEFAULT 1,
    pontos INT UNSIGNED DEFAULT 0,
    FOREIGN KEY (curso_id) REFERENCES cursos(id),
    FOREIGN KEY (nivel_id) REFERENCES niveis(id)
);

CREATE TABLE documentos (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    autor_id INT UNSIGNED,
    caminho_arquivo VARCHAR(255) NOT NULL,
    resumo_ia TEXT,
    data_upload TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (autor_id) REFERENCES usuarios(id)
);
CREATE TABLE materiais (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    autor VARCHAR(100),
    tipo ENUM('LIVRO', 'TCC', 'ARTIGO', 'RESUMO') NOT NULL,
    assunto VARCHAR(100),
    url_storage VARCHAR(255),
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE favoritos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    material_id INT NOT NULL,
    adicionado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
    FOREIGN KEY (material_id) REFERENCES materiais(id)
);

CREATE TABLE conquistas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100),
    xp_bonus INT,
    icone VARCHAR(10)
);

CREATE TABLE usuario_conquistas (
    usuario_id INT,
    conquista_id INT,
    data_ganho TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (usuario_id, conquista_id)
);