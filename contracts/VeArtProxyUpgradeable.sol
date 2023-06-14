// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Base64Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import {DateTime} from "@quant-finance/solidity-datetime/contracts/DateTime.sol";

import {IVeArtProxy} from "./interfaces/IVeArtProxy.sol";

contract VeArtProxyUpgradeable is IVeArtProxy, Initializable {
    using DateTime for uint256;

    function initialize() public initializer {}

    function _tokenURI(
        uint256 _tokenId,
        uint256 _balanceOf,
        uint256 _locked_end,
        uint256 /*_value*/
    ) external pure returns (string memory output) {
        string memory svg = _generateSVG(_tokenId, _balanceOf, _locked_end);
        string memory json = Base64Upgradeable.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "lock #',
                        toString(_tokenId),
                        '", "description": "Pearl locks can be used to boost gauge yields, vote on token emission, and receive bribes", "image": "data:image/svg+xml;base64,',
                        Base64Upgradeable.encode(bytes(svg)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));
    }

    function _generateSVG(uint256 _tokenId, uint256 _balanceOf, uint256 _locked_end) internal pure returns (string memory svg) {
        return
            string(
                abi.encodePacked(
                    '<?xml version="1.0" encoding="UTF-8"?><svg fill="none" preserveAspectRatio="xMinYMin meet" viewBox="0 0 300 300" xmlns="http://www.w3.org/2000/svg"><style type="text/css">.st0{fill-rule:evenodd;clip-rule:evenodd;fill:#2E5CFF;fill-opacity:0.7;}.st1{opacity:0.7;}.st2{fill:#2E5CFF;}.st3{font-family:"Lexend-Regular","Arial";}.st4{font-size:16px;}.st5{opacity:0.4;}.st6{font-size:8px;}.st7{font-size:12px;}</style><g clip-path="url(#k)"><rect width="300" height="300" fill="#fff"/><g clip-path="url(#j)" clip-rule="evenodd" fill-rule="evenodd" filter="url(#h)" opacity=".4"><path d="m-122.58-59.62c133.8 0 254.44 87.558 339.14 227.61 26.901 44.505 0.705 106.63-32.481 117.08-143.14 45.051-330.27-234.33-512.82-203-33.832 5.813-67.429 22.616-103.26 55.586-8.811 8.084-18.854 16.803-25.609 23.525 84.521-136.15 203.34-220.89 335.03-220.89v0.0908z" fill="url(#f)" opacity=".48"/><path d="m422.46-59.711c-133.86 0-254.55 87.582-339.28 227.68-26.971 44.608-0.6463 106.66 32.494 117.11 111.76 35.16 250.38-127.47 392.75-185.52 81.618-33.343 181.74-25.984 248.91 61.78-84.555-136.19-203.13-221.04-334.87-221.04z" fill="url(#e)" opacity=".48"/></g><g filter="url(#g)" shape-rendering="crispEdges"><circle cx="150.5" cy="114.5" r="79.5" fill="#fff" fill-opacity=".02"/><circle cx="150.5" cy="114.5" r="79.949" stroke="url(#d)" stroke-width=".8983"/></g><g clip-path="url(#i)"><path d="m149.68 158.3c25.038 0 45.335-20.203 45.335-45.124 0-24.922-20.297-45.125-45.335-45.125-25.037 0-45.334 20.203-45.334 45.125 0 24.921 20.297 45.124 45.334 45.124z" fill="url(#c)"/><path d="m149.71 158.3c-24.721 0-46.999-10.413-62.654-27.069-4.9743-5.293-0.1352-12.675 6.0052-13.92 26.438-5.358 61.01 27.865 94.736 24.139 6.247-0.69 12.458-2.691 19.074-6.614 1.628-0.964 3.479-1.996 4.729-2.8-15.61 16.188-37.568 26.264-61.891 26.264z" clip-rule="evenodd" fill="url(#b)" fill-rule="evenodd" opacity=".48"/><path d="m149.64 158.3c24.722 0 46.999-10.413 62.654-27.069 4.98-5.299 0.121-12.678-6.005-13.92-20.64-4.183-46.238 15.151-72.521 22.056-15.075 3.961-33.566 3.084-45.962-7.348 15.612 16.188 37.512 26.281 61.834 26.281z" clip-rule="evenodd" fill="url(#a)" fill-rule="evenodd" opacity=".48"/></g></g><defs><filter id="h" x="-74.247" y="-74.247" width="448.5" height="448.5" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur result="effect1_foregroundBlur_574_1183" stdDeviation="37.1237"/></filter><filter id="g" x="-1.7628" y="-1.8305" width="304.53" height="304.52" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feGaussianBlur in="BackgroundImageFix" stdDeviation="17.9661"/><feComposite in2="SourceAlpha" operator="in" result="effect1_backgroundBlur_574_1183"/><feColorMatrix in="SourceAlpha" result="hardAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0"/><feOffset dy="35.9322"/><feGaussianBlur stdDeviation="35.9322"/><feComposite in2="hardAlpha" operator="out"/><feColorMatrix values="0 0 0 0 0.179167 0 0 0 0 0.35975 0 0 0 0 1 0 0 0 0.1 0"/><feBlend in2="effect1_backgroundBlur_574_1183" result="effect2_dropShadow_574_1183"/><feBlend in="SourceGraphic" in2="effect2_dropShadow_574_1183" result="shape"/></filter><linearGradient id="f" x1="227.73" x2="-457.6" y1="115.22" y2="115.22" gradientUnits="userSpaceOnUse"><stop stop-color="#03B0DC" offset="0"/><stop stop-color="#0BA5DE" offset=".12"/><stop stop-color="#2188E3" offset=".32"/><stop stop-color="#465AED" offset=".58"/><stop stop-color="#781BFA" offset=".89"/><stop stop-color="#8C03FF" offset="1"/></linearGradient><linearGradient id="e" x1="757.33" x2="72.011" y1="115.18" y2="115.18" gradientUnits="userSpaceOnUse"><stop stop-color="#03B0DC" offset="0"/><stop stop-color="#0BA5DE" offset=".12"/><stop stop-color="#2188E3" offset=".32"/><stop stop-color="#465AED" offset=".58"/><stop stop-color="#781BFA" offset=".89"/><stop stop-color="#8C03FF" offset="1"/></linearGradient><linearGradient id="d" x1="150.5" x2="150.5" y1="35" y2="194" gradientUnits="userSpaceOnUse"><stop stop-color="#fff" offset="0"/><stop stop-color="#fff" stop-opacity="0" offset="1"/></linearGradient><radialGradient id="c" cx="0" cy="0" r="1" gradientTransform="translate(135.94 87.652) rotate(37.751) scale(72.271 51.31)" gradientUnits="userSpaceOnUse"><stop stop-color="#2E5CFF" offset="0"/><stop stop-color="#162435" offset="1"/></radialGradient><linearGradient id="b" x1="85" x2="211.6" y1="137.51" y2="137.51" gradientUnits="userSpaceOnUse"><stop stop-color="#03B0DC" offset="0"/><stop stop-color="#0BA5DE" offset=".12"/><stop stop-color="#2188E3" offset=".32"/><stop stop-color="#465AED" offset=".58"/><stop stop-color="#781BFA" offset=".89"/><stop stop-color="#8C03FF" offset="1"/></linearGradient><linearGradient id="a" x1="87.809" x2="214.36" y1="137.51" y2="137.51" gradientUnits="userSpaceOnUse"><stop stop-color="#03B0DC" offset="0"/><stop stop-color="#0BA5DE" offset=".12"/><stop stop-color="#2188E3" offset=".32"/><stop stop-color="#465AED" offset=".58"/><stop stop-color="#781BFA" offset=".89"/><stop stop-color="#8C03FF" offset="1"/></linearGradient><clipPath id="k"><rect width="300" height="300" fill="#fff"/></clipPath><clipPath id="j"><rect width="300" height="300" fill="#fff"/></clipPath><clipPath id="i"><rect transform="translate(85 49)" width="129.36" height="129.36" fill="#fff"/></clipPath></defs><path class="st0" d="m25.5 229.9c-0.9 0-1.7 0.3-2.3 1-0.6 0.6-1 1.4-1 2.3v1.9c-0.5 0-1 0.2-1.3 0.5-0.4 0.4-0.5 0.8-0.5 1.3v4.2c0 0.5 0.2 1 0.5 1.3 0.4 0.4 0.8 0.5 1.3 0.5h6.6c0.5 0 1-0.2 1.3-0.5 0.4-0.4 0.5-0.8 0.5-1.3v-4.1c0-0.5-0.2-1-0.5-1.3-0.4-0.4-0.8-0.5-1.3-0.5v-1.9c0-1.9-1.5-3.4-3.3-3.4zm2.3 5.2v-1.9c0-0.6-0.2-1.2-0.7-1.7-0.4-0.4-1-0.7-1.7-0.7s-1.2 0.2-1.7 0.7c-0.4 0.4-0.7 1-0.7 1.7v1.9h4.8z"/><g class="st1"><text class="st2 st3 st4" transform="translate(37.471 242.91)">',
                    formatUintToString(_balanceOf, 18),
                    '</text></g><g class="st5"><text class="st2 st3 st6" transform="translate(20 263)">Lock ends</text></g><g class="st5"><text class="st2 st3 st6" transform="translate(280 263)" text-anchor="end">Token ID</text></g><g class="st1"><text class="st2 st3 st7" transform="translate(20 280)">',
                    toDateString(_locked_end),
                    '</text></g><g class="st1"><text class="st2 st3 st7" transform="translate(280 280)" text-anchor="end">',
                    toString(_tokenId),
                    "</text></g></svg>"
                )
            );
    }

    /// @notice Converts a timestamp into a formatted date string representation
    /// @param timestamp The timestamp to be converted to a formatted date string
    /// @return string representation of the given timestamp
    function toDateString(uint256 timestamp) private pure returns (string memory) {
        (uint256 year, uint256 month, uint256 day) = timestamp.timestampToDate();
        string[12] memory monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        return string(abi.encodePacked(toString(day), " ", monthNames[month], ", ", toString(year)));
    }

    /// @notice Converts a uint256 value into a string representation
    /// @dev Optimizes for values with 32 digits or less using a bytes32 buffer, otherwise uses a dynamic bytes array
    /// @param value The uint256 value to be converted to a string
    /// @return string representation of the given uint256 value
    function toString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        // If the number of digits is more than 32, use a dynamic bytes array.
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            unchecked {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
        }
        return string(buffer);
    }

    /// @notice Formats a uint256 value into a string with decimals
    /// @dev The number of decimals specifies the position of the decimal point
    /// @param value The uint256 value to be formatted as a string
    /// @param decimals The number of decimal places
    /// @return A string representing the uint256 value with the given number of decimals
    function formatUintToString(uint256 value, uint256 decimals) public pure returns (string memory) {
        uint256 mainValue = value / (10 ** decimals);
        string memory mainStr = toString(mainValue);
        uint256 decimalValue = value % (10 ** decimals);
        // return early if decimal value is 0
        if (decimalValue == 0) {
            return mainStr;
        }
        string memory decimalStr = toString(decimalValue);
        decimalStr = padWithZeros(decimalStr, decimals);
        decimalStr = removeTrailingZeros(decimalStr);
        return string(abi.encodePacked(mainStr, ".", decimalStr));
    }

    /// @notice Pads a string with leading zeros until it reaches a specific length
    /// @param str The original string
    /// @param decimals The desired length of the string
    /// @return The string padded with leading zeros
    function padWithZeros(string memory str, uint256 decimals) private pure returns (string memory) {
        uint256 strLength = bytes(str).length;
        while (strLength < decimals) {
            str = string(abi.encodePacked("0", str));
            unchecked {
                ++strLength;
            }
        }
        return str;
    }

    /// @notice Removes trailing zeros from a string
    /// @param str The original string
    /// @return The string without trailing zeros
    function removeTrailingZeros(string memory str) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        uint256 strLength = strBytes.length;
        while (strLength > 0 && strBytes[strLength - 1] == "0") {
            unchecked {
                --strLength;
            }
        }
        return substring(strBytes, 0, strLength);
    }

    /// @notice Extracts a substring from a string
    /// @param strBytes The bytes representation of the original string
    /// @param startIndex The starting index of the substring
    /// @param endIndex The ending index of the substring
    /// @return The extracted substring
    function substring(bytes memory strBytes, uint256 startIndex, uint256 endIndex) private pure returns (string memory) {
        bytes memory result = new bytes(endIndex - startIndex);
        uint256 j = 0;
        for (uint256 i = startIndex; i < endIndex; ) {
            bytes(result)[j] = strBytes[i];
            unchecked {
                ++i;
                ++j;
            }
        }
        return string(result);
    }
}
