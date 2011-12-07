name := "cascading.scala"

version := "1.0"

scalaVersion := "2.9.1"

scalacOptions += "-deprecation"

resolvers ++= Seq( "maven.org" at "http://repo2.maven.org/maven2" )



libraryDependencies += "log4j" % "log4j" % "1.2.16"

libraryDependencies += "ch.qos.logback" % "logback-classic" % "0.9.28"

libraryDependencies += "org.scalatest" %% "scalatest" % "1.6.1" % "test"

libraryDependencies += "net.liftweb" %% "lift-json" % "2.4-M4"

libraryDependencies += "net.liftweb" %% "lift-json-ext" % "2.4-M4"

libraryDependencies += "org.scala-tools.time" %% "time" % "0.5"