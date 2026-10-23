FROM sbtscala/scala-sbt:eclipse-temurin-21.0.8_9_1.12.9_3.8.3 AS build
WORKDIR /src
COPY . .
RUN sbt example/stage

FROM eclipse-temurin:21-jre
COPY --from=build /src/example/target/universal/stage /app
EXPOSE 8080
ENTRYPOINT ["/app/bin/example"]
