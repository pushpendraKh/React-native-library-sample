import React from 'react'
import { View, Animated, NativeModules, Platform } from 'react-native'
import { Button } from '../Component/Common';

export default class ProfileScreen extends React.Component {
    constructor(props) {
      super(props)
    }

    componentWillMount() {
      this.position = new Animated.ValueXY(0,0)
    }

    render() {
      return (
        <View style={ styles.container}>
            <Button
               style = {styles.buttonStyle}
              onPress = { () => {
                if (Platform.OS == "ios") {
                  NativeModules.ZendriveHelper.setupHypertrack()
                } else {
                  console.log("Need to implement android native method")
                }
                
              }}
         >
            Present Action Sheet
       </Button>
        </View>
      );
    }
  }

  const styles = {
    container: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center'
    },

    buttonStyle: {
      height: 50,
      width: null,
      paddingLeft: 20,
      paddingRight: 20,
    }

  }