# --- Build Stage: Compile, Test, and Package ---
FROM gradle:7.6-jdk17 AS build
WORKDIR /app

# 1. Copy build scripts and wrapper
# /app/ 으로 복사
COPY . .
COPY gradlew settings.gradle build.gradle /app/
# /app/gradle/ 로 복사
COPY gradle gradle/
RUN chmod +x gradlew

# 2. Download dependencies
# 빌드타임에 의존성은 임시 컨테이너에 다운로드 되었다가 container가 실행되면 그곳에 커밋
RUN ./gradlew dependencies --no-daemon

# 3. Copy source and run tests + package
COPY src src/
# Run tests and package in one step to ensure test execution
# 백그라운드로 데몬실행안하고 JVM한번 쓰고 버림
# ./gradlew clean build하면 (jar&bootJar생성, 테스트) VS 아래는 bootJar만
#RUN ./gradlew clean test bootJar --no-daemon => Test안돌아감 되도록 수정 필요
RUN ./gradlew clean bootJar --no-daemon

# --- Runtime Stage: Lightweight JRE ---
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# Copy the fat JAR from build stage
# 런타임스테이지의 /app경로의 app.jar로 복사
COPY --from=build /app/build/libs/*.jar app.jar

# JVM memory options
ENV JAVA_OPTS="-Xms256m -Xmx512m"

EXPOSE 8080

# 컨테이너가 시작(docker build & docker run image)되면 아래 명령어가 실행됨
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

# .env는 컨테이너 실행시킬 때 넣어주자