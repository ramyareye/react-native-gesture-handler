import * as React from 'react';

import { Button, StyleSheet } from 'react-native';

import ComponentsScreen from './ComponentsScreen';
import FinalScreen from './FinalScreen';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import HomeScreen from './HomeScreen';
import { NavigationContainer } from '@react-navigation/native';
import ViewFlatteningScreen from './ViewFlatteningScreen';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import GestureCompositionScreen from './GestureCompositionScreen';

const Stack = createNativeStackNavigator();

export default function App() {
  return (
    <GestureHandlerRootView style={styles.container}>
      <NavigationContainer>
        <Stack.Navigator>
          <Stack.Screen
            name="HomeScreen"
            component={HomeScreen}
            options={({ navigation }) => ({
              title: 'RNGH FabricExample',
              headerRight: () => (
                <Button
                  onPress={() =>
                    navigation.navigate('GestureCompositionScreen')
                  }
                  title="Next"
                />
              ),
            })}
          />
          <Stack.Screen
            name="GestureCompositionScreen"
            component={GestureCompositionScreen}
            options={({ navigation }) => ({
              title: 'Gesture Composition',
              headerRight: () => (
                <Button
                  onPress={() => navigation.navigate('ComponentsScreen')}
                  title="Next"
                />
              ),
            })}
          />
          <Stack.Screen
            name="ComponentsScreen"
            component={ComponentsScreen}
            options={({ navigation }) => ({
              title: 'RNGH Components',
              headerRight: () => (
                <Button
                  onPress={() => navigation.navigate('ViewFlatteningScreen')}
                  title="Next"
                />
              ),
            })}
          />
          <Stack.Screen
            name="ViewFlatteningScreen"
            component={ViewFlatteningScreen}
            options={({ navigation }) => ({
              title: 'View Flattening',
              headerRight: () => (
                <Button
                  onPress={() => navigation.navigate('FinalScreen')}
                  title="Next"
                />
              ),
            })}
          />
          <Stack.Screen
            name="FinalScreen"
            component={FinalScreen}
            options={{ title: "That's all, folks!" }}
          />
        </Stack.Navigator>
      </NavigationContainer>
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});
