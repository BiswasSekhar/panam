import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Alert, ActivityIndicator } from 'react-native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { RootStackParamList } from '../../App';
import * as DocumentPicker from 'expo-document-picker';

type ScanPDFScreenNavigationProp = NativeStackNavigationProp<RootStackParamList, 'ScanPDF'>;

interface Props {
  navigation: ScanPDFScreenNavigationProp;
}

export default function ScanPDFScreen({ navigation }: Props) {
  const [loading, setLoading] = useState(false);
  const [extractedText, setExtractedText] = useState('');

  const pickDocument = async () => {
    try {
      const result = await DocumentPicker.getDocumentAsync({
        type: 'application/pdf',
      });

      if (result.assets && result.assets.length > 0) {
        setLoading(true);
        // In a real app, you'd use OCR library here
        // For now, we'll simulate extraction
        setTimeout(() => {
          setExtractedText('Sample extracted text from PDF\nAmount: ₹1,234.56\nDate: 2024-01-15\nMerchant: Sample Store');
          setLoading(false);
          Alert.alert('Success', 'PDF scanned! (Demo mode)');
        }, 2000);
      }
    } catch (error) {
      Alert.alert('Error', 'Failed to pick document');
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Scan Transaction PDF</Text>
      <Text style={styles.subtitle}>Upload bank statements or receipts</Text>

      <TouchableOpacity style={styles.uploadButton} onPress={pickDocument} disabled={loading}>
        <Text style={styles.uploadText}>📄 Select PDF</Text>
      </TouchableOpacity>

      {loading && (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#6366f1" />
          <Text style={styles.loadingText}>Scanning PDF...</Text>
        </View>
      )}

      {extractedText ? (
        <View style={styles.resultContainer}>
          <Text style={styles.resultTitle}>Extracted Data:</Text>
          <Text style={styles.resultText}>{extractedText}</Text>
          <TouchableOpacity 
            style={styles.createButton}
            onPress={() => {
              Alert.alert('Info', 'Auto-create transaction feature coming soon!');
              navigation.goBack();
            }}
          >
            <Text style={styles.createButtonText}>Create Transaction</Text>
          </TouchableOpacity>
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f9fafb',
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1f2937',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#6b7280',
    marginBottom: 32,
  },
  uploadButton: {
    backgroundColor: '#6366f1',
    padding: 20,
    borderRadius: 12,
    alignItems: 'center',
  },
  uploadText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '600',
  },
  loadingContainer: {
    marginTop: 40,
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: '#6b7280',
  },
  resultContainer: {
    marginTop: 32,
    backgroundColor: '#fff',
    padding: 20,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#e5e7eb',
  },
  resultTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1f2937',
    marginBottom: 12,
  },
  resultText: {
    fontSize: 14,
    color: '#6b7280',
    lineHeight: 22,
  },
  createButton: {
    backgroundColor: '#10b981',
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 16,
  },
  createButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});
