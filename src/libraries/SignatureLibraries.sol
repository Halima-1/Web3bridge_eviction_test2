// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library SignatureLibraries {
    error InvalidSignature();

    function recover(bytes32 digest, bytes memory siginature) internal pure returns (address) {
        if (siginature.length != 65) revert InvalidSignature();

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(siginature, 32))
            s := mload(add(siginature, 64))
            v := byte(0, mload(add(siginature, 96)))
        }

        if (uint256(s) > 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) revert InvalidSignature();

        if (v != 27 && v != 28) revert InvalidSignature();

        address signer = ecrecover(digest, v, r, s);

        if (signer == address(0)) revert InvalidSignature();

        return signer;
    }
}
