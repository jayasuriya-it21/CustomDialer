import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../contacts/presentation/screens/contact_detail_screen.dart';
import '../../../../widgets/contact_avatar.dart';
import '../bloc/dialpad_cubit.dart';
import '../bloc/dialpad_state.dart';

class DialpadScreenBloc extends StatelessWidget {
  const DialpadScreenBloc({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<DialpadCubit>()..initialize(), child: const _DialpadView());
  }
}

class _DialpadView extends StatelessWidget {
  const _DialpadView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: BlocBuilder<DialpadCubit, DialpadState>(
          builder: (context, state) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context), tooltip: 'Back'),
                      const Spacer(),
                      if (state.sims.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: cs.primaryContainer.withValues(alpha: 0.5)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sim_card_rounded, size: 14, color: cs.onPrimaryContainer),
                              const SizedBox(width: 4),
                              Text(
                                '${state.sims.length} SIMs',
                                style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 150),
                    style: TextStyle(fontSize: state.number.length > 14 ? 26 : 34, fontWeight: FontWeight.w300, letterSpacing: 1.5, color: cs.onSurface),
                    child: Text(state.number.isEmpty ? '\u200B' : _formatNum(state.number), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                if (state.matchingContacts.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: state.matchingContacts.length,
                      itemBuilder: (_, i) {
                        final c = state.matchingContacts[i];
                        final heroTag = 'dialpad_${c.name}_${c.number}';

                        return ListTile(
                          dense: true,
                          leading: ContactAvatar(name: c.name, radius: 18, heroTag: heroTag),
                          title: Text(
                            c.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(c.number, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ContactDetailScreen(name: c.name, number: c.number, heroTag: heroTag),
                              ),
                            );
                          },
                          trailing: IconButton(
                            icon: Icon(Icons.call_rounded, size: 18, color: cs.primary),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Call',
                            onPressed: () => context.read<DialpadCubit>().makeCallTo(c.number),
                          ),
                        );
                      },
                    ),
                  )
                else if (state.number.isNotEmpty)
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: TextButton.icon(
                          onPressed: () => context.read<DialpadCubit>().addToContacts(),
                          icon: Icon(Icons.person_add_rounded, size: 16, color: cs.primary),
                          label: Text('Add to contacts', style: TextStyle(color: cs.primary, fontSize: 14)),
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _row(context, ['1', '2', '3'], ['', 'ABC', 'DEF']),
                      _row(context, ['4', '5', '6'], ['GHI', 'JKL', 'MNO']),
                      _row(context, ['7', '8', '9'], ['PQRS', 'TUV', 'WXYZ']),
                      _row(context, ['*', '0', '#'], ['', '+', '']),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 56,
                        child: state.number.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.videocam_rounded, color: cs.primary),
                                tooltip: 'Video call',
                                onPressed: () => context.read<DialpadCubit>().openVideoCall(),
                              )
                            : IconButton(
                                icon: Icon(Icons.voicemail_rounded, color: cs.onSurfaceVariant),
                                tooltip: 'Voicemail',
                                onPressed: () {},
                              ),
                      ),
                      FloatingActionButton.large(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.read<DialpadCubit>().makeCall();
                        },
                        elevation: 0,
                        backgroundColor: cs.tertiaryContainer,
                        foregroundColor: cs.onTertiaryContainer,
                        child: const Icon(Icons.call_rounded, size: 36),
                      ),
                      SizedBox(
                        width: 56,
                        child: state.number.isNotEmpty
                            ? GestureDetector(
                                onLongPress: () {
                                  HapticFeedback.mediumImpact();
                                  context.read<DialpadCubit>().onClear();
                                },
                                child: IconButton(
                                  icon: Icon(Icons.backspace_outlined, color: cs.onSurfaceVariant),
                                  iconSize: 24,
                                  tooltip: 'Delete',
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    context.read<DialpadCubit>().onBackspace();
                                  },
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatNum(String n) {
    if (n.length <= 5) {
      return n;
    }
    if (n.length <= 10) {
      return '${n.substring(0, 5)} ${n.substring(5)}';
    }
    return n;
  }

  Widget _row(BuildContext context, List<String> digits, List<String> letters) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(3, (i) => _key(context, digits[i], letters[i]))),
    );
  }

  Widget _key(BuildContext context, String digit, String letters) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: digit == '*'
          ? 'Star'
          : digit == '#'
          ? 'Hash'
          : 'Digit $digit${letters.isNotEmpty ? ', $letters' : ''}',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.read<DialpadCubit>().onDigitPressed(digit);
          },
          onLongPress: digit == '0'
              ? () {
                  HapticFeedback.lightImpact();
                  context.read<DialpadCubit>().onDigitPressed('+');
                }
              : null,
          borderRadius: BorderRadius.circular(40),
          splashColor: cs.primary.withValues(alpha: 0.08),
          child: SizedBox(
            width: 80,
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  digit,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w400, color: cs.onSurface),
                ),
                if (letters.isNotEmpty) Text(letters, style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
