import sbt._
import Keys._
import sbtassembly.Plugin._

object WonkavisionBuild extends Build {

  lazy val buildVersion =  "0.1.0"
  lazy val playVersion = "2.0"
  
  lazy val typesafe = "Typesafe Repository" at "http://repo.typesafe.com/typesafe/releases/"
  lazy val typesafeSnapshot = "Typesafe Snapshots Repository" at "http://repo.typesafe.com/typesafe/snapshots/"
  lazy val maven = "maven.org" at "http://repo2.maven.org/maven2"

  lazy val root = Project(id = "wonkavision", base = file("."), settings = Project.defaultSettings).settings(
    version := buildVersion,
    organization := "com.hsihealth",
    resolvers += typesafe,
    resolvers += typesafeSnapshot,
    resolvers += maven    
  ).aggregate(wvcore, wvserver)

  lazy val wvcore = Project(id = "wonkavision-core", base = file("core"), settings = Project.defaultSettings).settings(
    version := buildVersion,
    organization := "com.hsihealth",
    resolvers += typesafe,
    resolvers += typesafeSnapshot,
    resolvers += maven,    
    scalacOptions ++= Seq("-unchecked", "-deprecation"),
    libraryDependencies += "log4j" % "log4j" % "1.2.16",
    libraryDependencies += "ch.qos.logback" % "logback-classic" % "0.9.28",
    libraryDependencies += "org.scalatest" %% "scalatest" % "1.6.1" % "test",
    libraryDependencies += "org.mockito" % "mockito-core" % "1.9.0-rc1" % "test",
    libraryDependencies += "org.scala-tools.time" %% "time" % "0.5",
    libraryDependencies += "net.liftweb" %% "lift-json" % "2.4-M4",
    libraryDependencies += "net.liftweb" %% "lift-json-ext" % "2.4-M4"

  )

  lazy val wvserver = Project(id = "wonkavision-server",
                              base = file("server"), settings = Project.defaultSettings)
  .dependsOn(wvcore)
  .settings(
    version := buildVersion,
    organization := "com.hsihealth",
    resolvers += typesafe,
    resolvers += typesafeSnapshot,
    resolvers += maven,    
    scalacOptions ++= Seq("-unchecked", "-deprecation"),
    libraryDependencies += "log4j" % "log4j" % "1.2.16",
    libraryDependencies += "ch.qos.logback" % "logback-classic" % "0.9.28",
    libraryDependencies += "org.scalatest" %% "scalatest" % "1.6.1" % "test",
    libraryDependencies += "org.mockito" % "mockito-core" % "1.9.0-rc1" % "test",
    libraryDependencies += "com.typesafe" %% "play-mini" % "2.0.1",
    libraryDependencies += "com.typesafe.akka" % "akka-testkit" % "2.0.1" % "test",
    libraryDependencies += "org.reflections" % "reflections" % "0.9.5",
    mainClass in (Compile, run) := Some("play.core.server.NettyServer")
  )
}
