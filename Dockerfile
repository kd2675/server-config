FROM gradle:8.7-jdk17 as builder
WORKDIR /build

# 🔥 더 세밀한 의존성 캐싱 (서브프로젝트별)
COPY build.gradle settings.gradle /build/
COPY common-core/build.gradle /build/common-core/
COPY common-database/build.gradle /build/common-database/
COPY common-log/build.gradle /build/common-log/
COPY server-config/build.gradle /build/server-config/
RUN gradle :server-config:dependencies --no-daemon

# 🎯 필요한 소스만 복사 (전체 대신)
COPY common-core/ /build/common-core/
COPY common-database/ /build/common-database/
COPY common-log/ /build/common-log/
COPY server-config/ /build/server-config/

# 빌드 (기존과 동일)
RUN gradle :server-config:clean :server-config:build --no-daemon --parallel

FROM openjdk:17-slim
WORKDIR /app

COPY --from=builder /build/server-config/build/libs/*.jar ./app.jar
ENV USE_PROFILE dev
ENV USE_EUREKA_URL http://kimd0.iptime.org:20210/eureka/


ENTRYPOINT ["java", "-Dspring.profiles.active=${USE_PROFILE}", "-Deureka.client.service-url.defaultZone=${USE_EUREKA_URL}", "-jar", "/app/app.jar"]