name := "wonkavision"

version := "0.1.0"

scalaVersion := "2.9.1"

scalacOptions += "-deprecation"

resolvers ++= Seq( "maven.org" at "http://repo2.maven.org/maven2",
									 "typesafe" at "http://repo.typesafe.com/typesafe/releases/" )


libraryDependencies += "se.scalablesolutions.akka" % "akka-actor" % "1.3-RC1"

libraryDependencies += "se.scalablesolutions.akka" % "akka-testkit" % "1.3-RC1" % "test"

libraryDependencies += "log4j" % "log4j" % "1.2.16"

libraryDependencies += "ch.qos.logback" % "logback-classic" % "0.9.28"

libraryDependencies += "org.scalatest" %% "scalatest" % "1.6.1" % "test"

libraryDependencies += "net.liftweb" %% "lift-json" % "2.4-M4"

libraryDependencies += "net.liftweb" %% "lift-json-ext" % "2.4-M4"

libraryDependencies += "org.scala-tools.time" %% "time" % "0.5"

libraryDependencies += "org.mockito" % "mockito-core" % "1.9.0-rc1" % "test"

