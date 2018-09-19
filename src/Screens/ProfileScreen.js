import React from 'react'
import { View, Animated, NativeModules, Platform } from 'react-native'
import { Button } from '../Component/Common';
import { RNHyperTrack as RNHyperTrackImport } from 'react-native-hypertrack'

export default class ProfileScreen extends React.Component {

    constructor(props) {
      super(props)
      this.RNHyperTrack = undefined;
      this.setupHyperTrackInstance()
      this.initializeHyperTrack()

    }

    componentWillMount() {
      this.position = new Animated.ValueXY(0,0)
    }

    setupHyperTrackInstance = () => {
      if (Platform.OS = "ios") {
        this.RNHyperTrack = NativeModules.RNHyperTrack;
      } else {
        this.RNHyperTrack = RNHyperTrackImport;
      }
    }

    initializeHyperTrack = () => {
      this.RNHyperTrack.initialize('pk_41daff593b32c8abd605515f4d8dd8e2af3637ed')
      this.RNHyperTrack.requestAlwaysLocationAuthorization("Hypertrack", "message");
  
      if (Platform.OS = "ios") {
        this.RNHyperTrack.requestMotionAuthorization();
      }
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