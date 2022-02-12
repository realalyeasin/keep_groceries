import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // text fields' controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  final CollectionReference _productss =
  FirebaseFirestore.instance.collection('products');

  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _nameController.text = documentSnapshot['name'];
      _priceController.text = documentSnapshot['price'].toString();
      _quantityController.text = documentSnapshot['quantity'].toString();
    }

    await showModalBottomSheet(
      backgroundColor: Colors.purple,
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                // prevent the soft keyboard from covering text fields
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                  ),
                ),
                TextField(
                  keyboardType:
                  const TextInputType.numberWithOptions(),
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'quantity',
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: Text(action == 'create' ? 'Create' : 'Update'),
                  onPressed: () async {
                    final String? name = _nameController.text;
                    final double? price = double.tryParse(_priceController.text);
                    final double? quantity = double.tryParse(_quantityController.text);
                    if (name != null && price != null ) {
                      if (action == 'create') {
                        // Persist a new product to Firestore
                        await _productss.add({"name": name, "price": price, 'quantity':quantity});
                      }

                      if (action == 'update') {
                        // Update the product
                        await _productss
                            .doc(documentSnapshot!.id)
                            .update({"name": name, "price": price});
                      }

                      // Clear the text fields
                      _nameController.text = '';
                      _priceController.text = '';
                      _quantityController.text ='';

                      // Hide the bottom sheet
                      Navigator.of(context).pop();
                    }
                  },
                )
              ],
            ),
          );
        });
  }

  // Deleteing a product by id
  Future<void> _deleteProduct(String productId) async {
    await _productss.doc(productId).delete();

    // Show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have successfully deleted a product')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keep Groceries'),
      ),
      // Using StreamBuilder to display all products from Firestore in real-time
      body: StreamBuilder(
        stream: _productss.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];
                return Card(
                  color: Colors.purple,
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(documentSnapshot['name']),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(documentSnapshot['price'].toString()),
                        ),
                        Text(documentSnapshot['quantity'].toString()),
                        Row(
                          children: [
                            // Press this button to edit a single product
                            IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _createOrUpdate(documentSnapshot)),
                            // This icon button is used to delete a single product
                            IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    _deleteProduct(documentSnapshot.id)),
                          ],
                        ),
                      ],
                      ),
                  ),
                  );
              },
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      // Add new product
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}