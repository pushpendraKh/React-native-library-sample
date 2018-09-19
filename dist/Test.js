"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const react_1 = require("react");
const react_native_1 = require("react-native");
const AppText = (props) => {
    const { style } = props;
    return (react_1.default.createElement(react_native_1.Text, { style: style }, props.children));
};
exports.AppText = AppText;
