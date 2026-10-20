package kz.stopscam.stopscam
import org.junit.Assert.*
import org.junit.Test

class CallPolicyTest {
    @Test fun defaultsAllowEvenWhenFlagged() { assertFalse(CallPolicy.block(false,"flagged",true,1.0,2000,1000)) }
    @Test fun unknownAllows() { assertFalse(CallPolicy.block(true,"unknown",true,1.0,2000,1000)) }
    @Test fun staleAllows() { assertFalse(CallPolicy.block(true,"flagged",true,1.0,1000,1000)) }
    @Test fun unconfirmedAllows() { assertFalse(CallPolicy.block(true,"flagged",false,1.0,2000,1000)) }
    @Test fun lowConfidenceAllows() { assertFalse(CallPolicy.block(true,"flagged",true,0.94,2000,1000)) }
    @Test fun invalidConfidenceAllows() { assertFalse(CallPolicy.block(true,"flagged",true,Double.NaN,2000,1000)) }
    @Test fun confirmedOptInBlocks() { assertTrue(CallPolicy.block(true,"flagged",true,0.95,2000,1000)) }
    @Test fun kazakhNormalization() { assertEquals("+77001234567",CallPolicy.normalize("8 (700) 123-45-67")) }
    @Test fun personalBlockWorksWithoutReputation() { assertEquals(true to "personal_block",CallPolicy.decide("blocked",false)) }
    @Test fun personalAllowOverridesReputation() { assertEquals(false to "personal_allow",CallPolicy.decide("trusted",true)) }
    @Test fun watchUsesReputation() { assertEquals(true to "reputation",CallPolicy.decide("watch",true)) }
    @Test fun removedRuleAllowsUnknown() { assertEquals(false to "unknown",CallPolicy.decide(null,false)) }}

