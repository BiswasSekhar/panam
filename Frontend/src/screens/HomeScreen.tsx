import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, RefreshControl } from 'react-native';
import { CompositeNavigationProp } from '@react-navigation/native';
import { BottomTabNavigationProp } from '@react-navigation/bottom-tabs';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { MainTabsParamList, RootStackParamList } from '../../App';
import { analytics } from '../api/api';
import { Summary } from '../types';

type HomeScreenNavigationProp = CompositeNavigationProp<
  BottomTabNavigationProp<MainTabsParamList, 'Home'>,
  NativeStackNavigationProp<RootStackParamList>
>;

interface Props {
  navigation: HomeScreenNavigationProp;
}

export default function HomeScreen({ navigation }: Props) {
  const [summary, setSummary] = useState<Summary | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    fetchSummary();
  }, []);

  const fetchSummary = async () => {
    try {
      const response = await analytics.getSummary();
      setSummary(response.data);
    } catch (error) {
      console.error('Failed to fetch summary', error);
    }
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await fetchSummary();
    setRefreshing(false);
  };

  return (
    <ScrollView 
      style={styles.container}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
    >
      <View style={styles.header}>
        <Text style={styles.greeting}>Welcome back!</Text>
        <Text style={styles.subtitle}>Here's your financial overview</Text>
      </View>

      <View style={styles.balanceCard}>
        <Text style={styles.balanceLabel}>Current Balance</Text>
        <Text style={styles.balanceAmount}>₹{summary?.balance?.toFixed(2) || '0.00'}</Text>
      </View>

      <View style={styles.statsGrid}>
        <View style={[styles.statCard, { backgroundColor: '#10b981' }]}>
          <Text style={styles.statLabel}>Income</Text>
          <Text style={styles.statAmount}>₹{summary?.total_income?.toFixed(2) || '0.00'}</Text>
        </View>
        <View style={[styles.statCard, { backgroundColor: '#ef4444' }]}>
          <Text style={styles.statLabel}>Expenses</Text>
          <Text style={styles.statAmount}>₹{summary?.total_expense?.toFixed(2) || '0.00'}</Text>
        </View>
      </View>

      <View style={styles.statsGrid}>
        <View style={[styles.statCard, { backgroundColor: '#f59e0b' }]}>
          <Text style={styles.statLabel}>Debts</Text>
          <Text style={styles.statAmount}>₹{summary?.total_debt?.toFixed(2) || '0.00'}</Text>
        </View>
        <View style={[styles.statCard, { backgroundColor: '#3b82f6' }]}>
          <Text style={styles.statLabel}>Credits</Text>
          <Text style={styles.statAmount}>₹{summary?.total_credit?.toFixed(2) || '0.00'}</Text>
        </View>
      </View>

      <TouchableOpacity 
        style={styles.addButton}
        onPress={() => navigation.navigate('AddTransaction')}
      >
        <Text style={styles.addButtonText}>+ Add Transaction</Text>
      </TouchableOpacity>

      <TouchableOpacity 
        style={styles.scanButton}
        onPress={() => navigation.navigate('ScanPDF')}
      >
        <Text style={styles.scanButtonText}>📄 Scan PDF</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f9fafb',
  },
  header: {
    padding: 20,
    paddingTop: 10,
  },
  greeting: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#1f2937',
  },
  subtitle: {
    fontSize: 16,
    color: '#6b7280',
    marginTop: 4,
  },
  balanceCard: {
    backgroundColor: '#6366f1',
    margin: 20,
    marginTop: 10,
    padding: 24,
    borderRadius: 16,
  },
  balanceLabel: {
    color: '#e0e7ff',
    fontSize: 16,
  },
  balanceAmount: {
    color: '#fff',
    fontSize: 40,
    fontWeight: 'bold',
    marginTop: 8,
  },
  statsGrid: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    gap: 12,
    marginBottom: 12,
  },
  statCard: {
    flex: 1,
    padding: 16,
    borderRadius: 12,
  },
  statLabel: {
    color: '#fff',
    fontSize: 14,
    opacity: 0.9,
  },
  statAmount: {
    color: '#fff',
    fontSize: 20,
    fontWeight: 'bold',
    marginTop: 4,
  },
  addButton: {
    backgroundColor: '#6366f1',
    margin: 20,
    padding: 18,
    borderRadius: 12,
    alignItems: 'center',
  },
  addButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '600',
  },
  scanButton: {
    backgroundColor: '#fff',
    marginHorizontal: 20,
    marginBottom: 20,
    padding: 18,
    borderRadius: 12,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#6366f1',
  },
  scanButtonText: {
    color: '#6366f1',
    fontSize: 18,
    fontWeight: '600',
  },
});
