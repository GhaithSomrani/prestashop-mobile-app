# Build Instructions

## Generating JSON Serialization Code

This project uses `json_serializable` for model serialization. Before running the app, you need to generate the `.g.dart` files.

### Run the following command:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate all the necessary `.g.dart` files for the models in the `lib/models/` directory.

### Alternative: Watch Mode

For development, you can use watch mode to automatically regenerate files when models change:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Generated Files

The following files will be generated:
- `lib/models/product.g.dart`
- `lib/models/category.g.dart`
- `lib/models/cart.g.dart`
- `lib/models/order.g.dart`
- `lib/models/customer.g.dart`
- `lib/models/address.g.dart`

**Note**: These files are not committed to version control. You must generate them locally before building the app.
