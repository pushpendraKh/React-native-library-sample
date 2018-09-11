import React from 'react';
import { Text, TouchableOpacity } from 'react-native';

const Button = (props) => {
    const { textStyle, buttonStyle } = styles
    const { onPress, children, style } = props
    return(
        <TouchableOpacity onPress = { onPress } style = {[style,buttonStyle]} >
            <Text style = { textStyle }>
                 { children } 
            </Text>
        </TouchableOpacity>    
         
    )

}

const styles = {

    textStyle: {
        color: '#007aff',
        fontSize: 16,
        fontWeight: '600',
    },

    buttonStyle: {
        height: 50,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#25cb7b',
        borderRadius: 5,
        borderColor: '#25cb7b',
        borderWidth: 1,
        margin: 20,
    },
}

export { Button }

