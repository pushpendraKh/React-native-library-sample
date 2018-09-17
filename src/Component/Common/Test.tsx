import React from 'react'
import { Text } from 'react-native'

const AppText = (props: any) => {
  const { style } = props
  return( 
    <Text style={style}>
        { props.children}
     </Text>
  )
} 

export {AppText}