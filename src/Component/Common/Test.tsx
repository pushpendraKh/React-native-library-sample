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

class Greeting {
    greet() {
        console.log("Hi Pushpendra!")
    }

    getGreeting() {
        return "Hi Pushpendra!"
    }
}

var object = new Greeting()
object.greet()
console.log(object.getGreeting)