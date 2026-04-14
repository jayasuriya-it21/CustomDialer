import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../contacts/presentation/screens/contact_detail_screen.dart';
import '../../../../widgets/contact_avatar.dart';
import '../../domain/entities/search_result_entity.dart';
import '../bloc/search_cubit.dart';
import '../bloc/search_state.dart';

class SearchScreenBloc extends StatefulWidget {
  const SearchScreenBloc({super.key});

  @override
  State<SearchScreenBloc> createState() => _SearchScreenBlocState();
}

class _SearchScreenBlocState extends State<SearchScreenBloc> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (_) => getIt<SearchCubit>()..initialize(),
      child: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                    child: Hero(
                      tag: 'search_bar_hero',
                      child: SearchBar(
                        controller: _controller,
                        focusNode: _focusNode,
                        hintText: AppConstants.searchHint,
                        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context), tooltip: 'Back'),
                        onChanged: (value) {
                          context.read<SearchCubit>().queryChanged(value);
                        },
                        trailing: [
                          if (_controller.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Clear',
                              onPressed: () {
                                _controller.clear();
                                context.read<SearchCubit>().queryChanged('');
                              },
                            ),
                          const SizedBox(width: 8),
                        ],
                        elevation: const WidgetStatePropertyAll(0),
                        backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(child: _buildBody(context, state)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, SearchState state) {
    final cs = Theme.of(context).colorScheme;

    if (state.query.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text('Search by name or number', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    if (state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text('No results', style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(padding: const EdgeInsets.only(top: 4), itemCount: state.results.length, separatorBuilder: (_, _) => const Divider(height: 1, indent: 72), itemBuilder: (_, i) => _buildResultItem(context, state.results[i]));
  }

  Widget _buildResultItem(BuildContext context, SearchResultEntity result) {
    final cs = Theme.of(context).colorScheme;
    final heroTag = result.isContact ? 'search_${result.displayName}_${result.number}' : null;

    return ListTile(
      leading: ContactAvatar(name: result.displayName, heroTag: heroTag),
      title: Text(result.displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: result.name.isNotEmpty ? Text(result.number, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.call_rounded, color: cs.primary, size: 20),
            tooltip: 'Call',
            onPressed: () => context.read<SearchCubit>().makeCall(result.number),
          ),
          IconButton(
            icon: Icon(Icons.message_rounded, color: cs.onSurfaceVariant, size: 20),
            tooltip: 'Message',
            onPressed: () => context.read<SearchCubit>().openSms(result.number),
          ),
        ],
      ),
      onTap: () {
        if (!result.isContact || result.name.isEmpty) {
          context.read<SearchCubit>().makeCall(result.number);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContactDetailScreen(name: result.name, number: result.number, heroTag: heroTag),
          ),
        );
      },
    );
  }
}
