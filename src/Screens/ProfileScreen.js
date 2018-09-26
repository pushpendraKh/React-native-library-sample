import React from 'react'
import { View, Animated, NativeModules, Platform, Alert } from 'react-native'
import { Button } from '../Component/Common';
import { RNHyperTrack as RNHyperTrackImport } from 'react-native-hypertrack'

export default class ProfileScreen extends React.Component {

    constructor(props) {
      super(props)
      this.RNHyperTrack = undefined;
      this.setupHyperTrackInstance()
      this.initializeHyperTrack()

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
      this.RNHyperTrack.requestMotionAuthorization();
  
      if (Platform.OS = "ios") {
      }

      this.RNHyperTrack.locationAuthorizationStatus().then((result) => {
        // Handle locationAuthorizationStatus API result here
        console.log('locationAuthorizationStatus: ', result);
      });
    }

    render() {
      return (
        <View style={ styles.container}>
            <Button
               style = {styles.buttonStyle}
              onPress = { () => {
                if (Platform.OS == "ios") {
                  NativeModules.ZendriveHelper.openDocumentPicker()
                } else {
                  Alert.alert("Dhruva", "Need to open document folder in android via native method")
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