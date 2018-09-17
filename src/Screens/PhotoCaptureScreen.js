import React from 'react';
import { View, NativeModules } from 'react-native';
import UploadPhoto from '../Component/PhotoUpload';
import { Spinner} from '../Component/Common'
import firebase from 'react-native-firebase'

export default class PhotoCaptureScreen extends React.Component {

    state = {
      isLoading: false,
      imageUri: 'https://www.sparklabs.com/forum/styles/comboot/theme/images/default_avatar.jpg'
    }
  
    
    componentWillMount() {
      firebase.analytics().setCurrentScreen('photoUpload');
    }
  
    componentDidMount() {
      firebase.analytics().logEvent("photo_upload_screen_appeared")
    }
  
    shouldStartLoading = (flag) => {
      this.setState({
        isLoading: flag
      })
    }
  
    didGetResponse =(response) => {
      console.log(response)
        this.setState({
          isLoading: false,
          imageUri: (response.didCancel)  ? this.state.imageUri : response.uri
        })
    }
  
    renderPhotoCapture =() => {
      if (this.state.isLoading) {
        return <Spinner/>
      } else {
        return(
          <UploadPhoto
          onStart = { () => {
            this.shouldStartLoading(true)
          }}
          onResponse = { this.didGetResponse }
          imageUri = { this.state.imageUri }
          />
        )
      }
    }
  
    render() {
      console.log("this.state", this.state);
      return (
        <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
            { this.renderPhotoCapture() }
        </View>
      )
    }
  }