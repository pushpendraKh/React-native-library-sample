import { NavigationActions } from 'react-navigation'

let navigator;

setTopLevelNavigator = (navigatorRef) => {
    navigator = navigatorRef
}

navigateToWebView = () => {
    navigator.navigate('Web', {
        url: 'https://in.linkedin.com/in/janahvee-shah-a53013101'
    })
}

function navigate(routeName, params) {
    navigator.dispatch(
      NavigationActions.navigate({
        routeName,
        params,
      })
    );
  }

export default {
    navigate,
    setTopLevelNavigator,
  };