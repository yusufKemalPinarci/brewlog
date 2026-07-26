import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/brew_theme.dart';
import 'features/dial_in/data/repositories/local_dial_in_repository.dart';
import 'features/dial_in/presentation/bloc/dial_in_cubit.dart';
import 'features/dial_in/presentation/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr');
  final repository = LocalDialInRepository();
  runApp(BrewCrewApp(repository: repository));
}

class BrewCrewApp extends StatelessWidget {
  const BrewCrewApp({super.key, required this.repository});

  final DialInRepository repository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<DialInRepository>.value(
      value: repository,
      child: BlocProvider(
        create: (_) => DialInCubit(repository)..load(),
        child: MaterialApp(
          title: 'BrewLog',
          debugShowCheckedModeBanner: false,
          theme: BrewTheme.dark(),
          home: const HomePage(),
        ),
      ),
    );
  }
}
