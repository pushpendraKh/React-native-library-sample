import React, { Component } from 'react';
import { View } from 'react-native';

const Card = (props) => {
    return(
        <View style = {[props.style, styles.containerStyle]}>
            { props.children }
        </View>  
    )

}

const styles = {
    containerStyle: {
        borderWidth: 1,
        borderRadius: 2,
        borderColor: '#ddd',
        borderBottomWidth: 0,

        showdowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 7,
        elevation: 2,
        marginLeft: 5,
        marginRight: 5,
        marginTop: 10,
    },
}
export { Card }

