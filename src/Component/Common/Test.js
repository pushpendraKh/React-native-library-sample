// import React from 'react'
// import { Text } from 'react-native'
// const AppText = (props: any) => {
//   const { style } = props
//   return( 
//     <Text style={style}>
//         { props.children}
//      </Text>
//   )
// } 
// export {AppText}
var Greeting = /** @class */ (function () {
    function Greeting() {
    }
    Greeting.prototype.greet = function () {
        console.log("Hi Pushpendra!");
    };
    Greeting.prototype.getGreeting = function () {
        return "Hi Pushpendra!";
    };
    return Greeting;
}());
var object = new Greeting();
object.greet();
console.log(object.getGreeting);
