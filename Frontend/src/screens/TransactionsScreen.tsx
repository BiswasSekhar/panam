import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity, Alert } from 'react-native';
import { transactions } from '../api/api';
import { Transaction } from '../types';

export default function TransactionsScreen() {
  const [txnList, setTxnList] = useState<Transaction[]>([]);

  useEffect(() => {
    fetchTransactions();
  }, []);

  const fetchTransactions = async () => {
    try {
      const response = await transactions.getAll();
      setTxnList(response.data);
    } catch (error) {
      console.error('Failed to fetch transactions', error);
    }
  };

  const handleDelete = async (id: string) => {
    Alert.alert('Delete Transaction', 'Are you sure?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: async () => {
          try {
            await transactions.delete(id);
            fetchTransactions();
          } catch (error) {
            Alert.alert('Error', 'Failed to delete transaction');
          }
        },
      },
    ]);
  };

  const renderItem = ({ item }: { item: Transaction }) => (
    <TouchableOpacity 
      style={styles.card}
      onLongPress={() => handleDelete(item.id)}
    >
      <View style={styles.cardHeader}>
        <Text style={styles.category}>{item.category}</Text>
        <Text style={[styles.amount, item.type === 'income' ? styles.income : styles.expense]}>
          {item.type === 'income' ? '+' : '-'}₹{item.amount.toFixed(2)}
        </Text>
      </View>
      <Text style={styles.description}>{item.description}</Text>
      <Text style={styles.date}>{item.date}</Text>
      {item.is_recurring && (
        <Text style={styles.recurring}>🔄 {item.recurring_frequency}</Text>
      )}
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      <FlatList
        data={txnList}
        renderItem={renderItem}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.list}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f9fafb',
  },
  list: {
    padding: 16,
  },
  card: {
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#e5e7eb',
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  category: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1f2937',
  },
  amount: {
    fontSize: 20,
    fontWeight: 'bold',
  },
  income: {
    color: '#10b981',
  },
  expense: {
    color: '#ef4444',
  },
  description: {
    fontSize: 14,
    color: '#6b7280',
    marginBottom: 4,
  },
  date: {
    fontSize: 12,
    color: '#9ca3af',
  },
  recurring: {
    fontSize: 12,
    color: '#6366f1',
    marginTop: 4,
  },
});
