import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity, Alert } from 'react-native';
import { debtsCredits } from '../api/api';
import { DebtCredit } from '../types';

export default function DebtsCreditsScreen() {
    const [items, setItems] = useState<DebtCredit[]>([]);

    useEffect(() => {
        fetchDebtsCredits();
    }, []);

    const fetchDebtsCredits = async () => {
        try {
            const response = await debtsCredits.getAll();
            setItems(response.data);
        } catch (error) {
            console.error('Failed to fetch debts/credits', error);
        }
    };

    const handleSettle = async (id: string) => {
        Alert.alert('Settle', 'Mark as settled?', [
            { text: 'Cancel', style: 'cancel' },
            {
                text: 'Settle',
                onPress: async () => {
                    try {
                        await debtsCredits.settle(id);
                        fetchDebtsCredits();
                    } catch (error) {
                        Alert.alert('Error', 'Failed to settle');
                    }
                },
            },
        ]);
    };

    const renderItem = ({ item }: { item: DebtCredit }) => (
        <TouchableOpacity
            style={[styles.card, item.status === 'settled' && styles.settledCard]}
            onPress={() => item.status === 'pending' && handleSettle(item.id)}
        >
            <View style={styles.cardHeader}>
                <Text style={styles.personName}>{item.person_name}</Text>
                <Text style={[styles.amount, item.type === 'credit' ? styles.credit : styles.debt]}>
                    ₹{item.amount.toFixed(2)}
                </Text>
            </View>
            <Text style={styles.description}>{item.description}</Text>
            {item.due_date && <Text style={styles.dueDate}>Due: {item.due_date}</Text>}
            <Text style={[styles.status, item.status === 'settled' && styles.settledStatus]}>
                {item.status === 'settled' ? '✓ Settled' : 'Pending'}
            </Text>
        </TouchableOpacity>
    );

    return (
        <View style={styles.container}>
            <FlatList
                data={items}
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
    settledCard: {
        opacity: 0.6,
    },
    cardHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 8,
    },
    personName: {
        fontSize: 18,
        fontWeight: '600',
        color: '#1f2937',
    },
    amount: {
        fontSize: 20,
        fontWeight: 'bold',
    },
    debt: {
        color: '#f59e0b',
    },
    credit: {
        color: '#3b82f6',
    },
    description: {
        fontSize: 14,
        color: '#6b7280',
        marginBottom: 4,
    },
    dueDate: {
        fontSize: 12,
        color: '#9ca3af',
        marginBottom: 4,
    },
    status: {
        fontSize: 12,
        color: '#f59e0b',
        fontWeight: '600',
    },
    settledStatus: {
        color: '#10b981',
    },
});
