FROM sbtscala/scala-sbt:eclipse-temurin-21.0.8_9_1.12.9_3.8.3 AS build
WORKDIR /src
COPY . .
RUN sbt stage

FROM eclipse-temurin:21-jre
COPY --from=build /src/target/universal/stage /app
EXPOSE 8082
ENTRYPOINT ["/app/bin/ghostspeak-auth"]
