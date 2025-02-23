// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "ds-test/test.sol";
import "../DoublyLinkedList.sol";
import "./Array.t.sol";
import "forge-std/Vm.sol";

struct U256 {
    uint256 value;
    uint256 prev;
    uint256 next;
}

contract IndexableDoublyLinkedListTest is DSTest, MemoryBrutalizer {
    Vm vm = Vm(HEVM_ADDRESS);

    using IndexableDoublyLinkedListLib for DoublyLinkedList;
    function setUp() public {}

    function testFuzzBrutalizeMemoryIDLL(bytes memory randomBytes, uint16 num) public brutalizeMemory(randomBytes) {
        vm.assume(num < 5000);
        DoublyLinkedList pa = IndexableDoublyLinkedListLib.newIndexableDoublyLinkedList(num);
        uint256 lnum = uint256(num);
        uint256 init = 1337;
        for (uint256 i;  i < lnum; i++) {
            U256 memory b = U256({value: init + i, prev: 0, next: 0});
            pa = pa.push_and_link(pointer(b), 0x20, 0x40);
        }

        for (uint256 i; i < lnum; i++) {
            bytes32 ptr = pa.get(i);
            uint256 k;
            assembly {
                k := mload(ptr)
            }
            assertEq(k, init+i);
        }
    }

    function testIndexableDoublyLinkedList() public {
        DoublyLinkedList pa = IndexableDoublyLinkedListLib.newIndexableDoublyLinkedList(5);
        U256 memory a = U256({value: 100, prev: 0, next: 0});
        pa = pa.push_no_link(pointer(a));
        for (uint256 i; i < 6; i++) {
            U256 memory b = U256({value: 101 + i, prev: 0, next: 0});
            pa = pa.push_and_link(pointer(b), 0x20, 0x40);
        }

        for (uint256 i; i < 7; i++) {
            bytes32 ptr = pa.get(i);
            uint256 k;
            assembly {
                k := mload(ptr)
            }
            assertEq(k, 100 + i);
        }
    }

    function pointer(U256 memory a) internal pure returns(bytes32 ptr) {
        assembly {
            ptr := a
        }
    }
}

contract DoublyLinkedListTest is DSTest, MemoryBrutalizer {
    Vm vm = Vm(HEVM_ADDRESS);

    using DoublyLinkedListLib for DoublyLinkedList;
    function setUp() public {}

    function testFuzzBrutalizeMemoryDLL(bytes memory randomBytes, uint16 num) public brutalizeMemory(randomBytes) {
        vm.assume(num < 5000);
        vm.assume(num > 0);
        DoublyLinkedList pa = DoublyLinkedListLib.newDoublyLinkedList(0x20, 0x40);
        uint256 lnum = uint256(num);
        uint256 init = 1337;
        for (uint256 i;  i < lnum; i++) {
            U256 memory b = U256({value: init + i, prev: 0, next: 0});
            pa = pa.push_and_link(pointer(b));
        }

        bytes32 element = pa.head();
        bool success = true;
        uint256 ctr = 0;
        while (success) {
            // convert the ptr to our struct type
            U256 memory elem = fromPointer(element);
            // check it is what we expected
            assertEq(elem.value, 1337 + ctr);
            ++ctr;
            // walk to the next element
            (success, element) = pa.next(element);
        }
        assertEq(ctr, num);

        element = pa.tail();
        success = true;
        ctr = 0;
        while (success) {
            // convert the ptr to our struct type
            U256 memory elem = fromPointer(element);
            // check it is what we expected
            assertEq(elem.value, 1337 + num - ctr - 1);
            ++ctr;
            // walk to the next element
            (success, element) = pa.previous(element);
        }
        assertEq(ctr, num);
    }

    function testDoublyLinkedList() public {
        DoublyLinkedList pa = DoublyLinkedListLib.newDoublyLinkedList(0x20, 0x40);
        for (uint256 i; i < 7; i++) {
            U256 memory b = U256({value: 100 + i, prev: 0, next: 0});
            pa = pa.push_and_link(pointer(b));
        }

        bytes32 element = pa.head();
        bool success = true;
        uint256 ctr = 0;
        while (success) {
            // convert the ptr to our struct type
            U256 memory elem = fromPointer(element);
            // check it is what we expected
            assertEq(elem.value, 100 + ctr);
            ++ctr;
            // walk to the next element
            (success, element) = pa.next(element);
            require(ctr <= 7);
        }
        assertEq(ctr, 7);

        element = pa.tail();
        success = true;
        ctr = 0;
        while (success) {
            // convert the ptr to our struct type
            U256 memory elem = fromPointer(element);
            // check it is what we expected
            assertEq(elem.value, 106 - ctr);
            ++ctr;
            // walk to the next element
            (success, element) = pa.previous(element);
        }
        assertEq(ctr, 7);
    }

    function pointer(U256 memory a) internal pure returns (bytes32 ptr) {
        assembly {
            ptr := a
        }
    }

    function fromPointer(bytes32 ptr) internal pure returns (U256 memory a) {
        assembly ("memory-safe") {
            a := ptr
        }
    }
}