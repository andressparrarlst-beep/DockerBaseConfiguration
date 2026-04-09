# ---------- Etapa de build ----------
FROM maven:3.9.9-eclipse-temurin-21 AS build

WORKDIR /app

# Instalar git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Clonar SOLO la rama main, con profundidad 1 (sin historial ni otras ramas)
RUN git clone --branch main --single-branch --depth 1 https://github.com/andressparrarlst-beep/repo-sistemas-dis.git .

# Compilar y empaquetar (sin correr tests)
RUN mvn clean package -DskipTests

# ---------- Etapa final (imagen mínima) ----------
FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

# Copiar solo el JAR generado
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
