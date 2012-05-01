package org.wonkavision.redis.serialization

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers


class MessagePackSpec extends Spec with BeforeAndAfter with ShouldMatchers {

	describe("writeMap & readMap") {
		it("should serialize a string,string map to a byte array") {
			val original = Map(
				"hi" -> "ho",
				"he" -> "ha"
			)

			val bytes = MessagePack.writeMap(original)
			val rehydrated = MessagePack.readMap(bytes)
			rehydrated should equal (original)
		}
	}
}