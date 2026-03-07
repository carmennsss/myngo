CREATE DATABASE IF NOT EXISTS myngodb;
USE myngodb;

-- 1. USUARIOS Y AUTENTICACIÓN
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_usuario VARCHAR(150) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    contrasena VARCHAR(255) NOT NULL,
    es_verificado BOOLEAN DEFAULT FALSE,
    rating_actual DECIMAL(3,2) DEFAULT 0.0,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. PERFILES Y GAMIFICACIÓN
CREATE TABLE perfiles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT UNIQUE,
    biografia TEXT,
    url_avatar VARCHAR(500),
    puntos INT DEFAULT 0,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_perfil_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT chk_puntos_limite CHECK (puntos <= 5000)
) ENGINE=InnoDB;

-- 3. TIENDA DE MEJORAS Y COSMÉTICOS
CREATE TABLE catalogo_mejoras (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo VARCHAR(50), -- 'MARCO', 'FONDO', 'BADGE'
    precio_puntos INT NOT NULL,
    url_recurso VARCHAR(500)
) ENGINE=InnoDB;

CREATE TABLE mejoras_usuario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT,
    mejora_id INT,
    esta_equipada BOOLEAN DEFAULT FALSE,
    fecha_adquisicion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(usuario_id, mejora_id),
    CONSTRAINT fk_mejora_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_mejora_catalogo FOREIGN KEY (mejora_id) REFERENCES catalogo_mejoras(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 4. COMUNIDADES
CREATE TABLE comunidades (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    creador_id INT,
    url_portada VARCHAR(500),
    es_publica BOOLEAN DEFAULT TRUE,
    es_verificada BOOLEAN DEFAULT FALSE,
    rating_actual DECIMAL(3,2) DEFAULT 0.0,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_comunidad_creador FOREIGN KEY (creador_id) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE miembros_comunidades (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT,
    comunidad_id INT,
    rol VARCHAR(20) DEFAULT 'MIEMBRO',
    estado_peticion VARCHAR(20) DEFAULT 'ACEPTADO',
    fecha_union TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(usuario_id, comunidad_id),
    CONSTRAINT fk_miembro_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_miembro_comunidad FOREIGN KEY (comunidad_id) REFERENCES comunidades(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 5. SISTEMA DE RATING (DIARIO)
CREATE TABLE votos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    votante_id INT,
    receptor_usuario_id INT NULL,
    receptor_comunidad_id INT NULL,
    estrellas INT CHECK (estrellas BETWEEN 0 AND 5),
    fecha_voto DATE NOT NULL,
    CONSTRAINT un_voto_por_dia_usuario UNIQUE (votante_id, receptor_usuario_id, fecha_voto),
    CONSTRAINT un_voto_por_dia_comunidad UNIQUE (votante_id, receptor_comunidad_id, fecha_voto),
    CONSTRAINT fk_voto_votante FOREIGN KEY (votante_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_voto_usuario FOREIGN KEY (receptor_usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_voto_comunidad FOREIGN KEY (receptor_comunidad_id) REFERENCES comunidades(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 6. CONTENIDO Y MODERACIÓN POR IA
CREATE TABLE publicaciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    autor_id INT,
    comunidad_id INT NULL,
    titulo VARCHAR(200),
    contenido_texto TEXT,
    url_archivo_s3 VARCHAR(500) NOT NULL,
    relacion_aspecto FLOAT DEFAULT 1.0,
    es_valido_ia BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_post_autor FOREIGN KEY (autor_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_post_comunidad FOREIGN KEY (comunidad_id) REFERENCES comunidades(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE comentarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    publicacion_id INT,
    autor_id INT,
    contenido TEXT NOT NULL,
    es_valido_ia BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_coment_post FOREIGN KEY (publicacion_id) REFERENCES publicaciones(id) ON DELETE CASCADE,
    CONSTRAINT fk_coment_autor FOREIGN KEY (autor_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 7. GALERÍAS Y RETOS
CREATE TABLE imagenes_galeria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    propietario_id INT,
    comunidad_id INT NULL,
    url_s3 VARCHAR(500) NOT NULL,
    relacion_aspecto FLOAT DEFAULT 1.0,
    es_publica BOOLEAN DEFAULT TRUE,
    fecha_subida TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_galeria_propietario FOREIGN KEY (propietario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_galeria_comunidad FOREIGN KEY (comunidad_id) REFERENCES comunidades(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE colecciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT,
    nombre_coleccion VARCHAR(100) NOT NULL,
    categoria VARCHAR(50),
    es_privada BOOLEAN DEFAULT FALSE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_coleccion_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE imagenes_en_colecciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    coleccion_id INT,
    imagen_id INT,
    UNIQUE(coleccion_id, imagen_id),
    CONSTRAINT fk_en_coleccion FOREIGN KEY (coleccion_id) REFERENCES colecciones(id) ON DELETE CASCADE,
    CONSTRAINT fk_en_imagen FOREIGN KEY (imagen_id) REFERENCES imagenes_galeria(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 8. COMUNICACIÓN (CHATS)
CREATE TABLE salas_chat (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    comunidad_id INT NULL,
    es_grupal BOOLEAN DEFAULT FALSE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sala_comunidad FOREIGN KEY (comunidad_id) REFERENCES comunidades(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE participantes_chat (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sala_id INT,
    usuario_id INT,
    fecha_union TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(sala_id, usuario_id),
    CONSTRAINT fk_part_sala FOREIGN KEY (sala_id) REFERENCES salas_chat(id) ON DELETE CASCADE,
    CONSTRAINT fk_part_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE mensajes_chat (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sala_id INT,
    emisor_id INT,
    contenido TEXT,
    url_archivo_s3 VARCHAR(500),
    fecha_envio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_msj_sala FOREIGN KEY (sala_id) REFERENCES salas_chat(id) ON DELETE CASCADE,
    CONSTRAINT fk_msj_emisor FOREIGN KEY (emisor_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 9. SOCIAL Y NOTIFICACIONES
CREATE TABLE seguimientos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    seguidor_id INT,
    seguido_usuario_id INT NULL,
    seguida_comunidad_id INT NULL,
    estado VARCHAR(20) DEFAULT 'ACEPTADO',
    fecha_seguimiento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unico_seguimiento_u UNIQUE (seguidor_id, seguido_usuario_id),
    CONSTRAINT unico_seguimiento_c UNIQUE (seguidor_id, seguida_comunidad_id),
    CONSTRAINT fk_seg_seguidor FOREIGN KEY (seguidor_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_seg_usuario FOREIGN KEY (seguido_usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_seg_comunidad FOREIGN KEY (seguida_comunidad_id) REFERENCES comunidades(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE me_gustas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT,
    publicacion_id INT,
    fecha_like TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(usuario_id, publicacion_id),
    CONSTRAINT fk_like_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_like_post FOREIGN KEY (publicacion_id) REFERENCES publicaciones(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE notificaciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT,
    tipo VARCHAR(50), 
    mensaje TEXT NOT NULL,
    leida BOOLEAN DEFAULT FALSE,
    referencia_usuario_id INT NULL,
    referencia_comunidad_id INT NULL,
    fecha_notificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notif_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_notif_ref_u FOREIGN KEY (referencia_usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_notif_ref_c FOREIGN KEY (referencia_comunidad_id) REFERENCES comunidades(id) ON DELETE CASCADE
) ENGINE=InnoDB;