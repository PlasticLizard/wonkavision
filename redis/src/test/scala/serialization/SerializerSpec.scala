package org.wonkavision.redis.serialization

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import org.wonkavision.server.cubes.PingCube

class SerializerSpec extends Spec with BeforeAndAfter with ShouldMatchers {

	val cube = new PingCube()
	implicit val dim = cube.dimensions("ding")
	implicit val agg = cube.aggregations("pong")
	val serializer = new MessagePackSerializer()

	describe("dimension serialization"){
		describe("write & read"){
			it("should serialize and deserialize a dimension member"){
				val orig = dim.createMember(Map("name"->"t1", "id"->1))
				val bytes = serializer.write(orig)
				val deser = serializer.readDimensionMember(Some(bytes)).get
				deser.key should equal (orig.key)
				deser.caption should equal (orig.caption)
			}
		}
	}

	describe("aggregate serialization"){
		describe("write & read"){
			it("should serialize and deserialize an aggregate"){
				val orig = agg.createAggregate(List("ding","dong"),Map("ding"->1, "dong"->2, "cling"->1))
				val bytes = serializer.write(orig)
				val deser = serializer.readAggregate(List("ding","dong"),Some(bytes)).get
				deser.key should equal (orig.key)
				deser.measures should equal (orig.measures)
			}
		}
	}
	
}