import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/hint_banner.dart';
import '/core/widgets/pill_button.dart';
import '/features/advisor_ai/widgets/advisor_sheet.dart';
import '/features/dashboard/dashboard_viewmodel.dart';
import '/features/dashboard/models/activity_session.dart';
import 'add_entry_sheet.dart';
import 'arrival_card.dart';
import 'coverage_warning.dart';
import 'pending_invites_card.dart';
import 'roster_empty_card.dart';
import 'roster_status_bar.dart';
import 'roster_tile.dart';
import 'runner_card.dart';
import 'section_header.dart';
import 'share_expense_sheet.dart';
import 'shared_expense_tile.dart';
import '/generated/assets.dart';

class DashboardBody extends StatelessWidget {
  final DashboardViewModel viewModel;

  const DashboardBody({super.key, required this.viewModel});

  static ActivitySession _placeholderSession() => ActivitySession(
    id: 'mock',
    date: DateTime.now(),
    status: SessionStatus.open,
    headcount: 3,
    totalUnits: 6,
    totalCovers: 3,
    runnerName: 'Someone',
    runnerId: 'mock',
  );

  @override
  Widget build(BuildContext context) {
    final pack = PackService.instance.pack;
    final modules = pack.modules;
    final labels = pack.labels;

    final isLoading = Skeletonizer.of(context).enabled;
    // Today's row only exists once someone adds an entry, assigns a runner or
    // pings. Until then today is simply open with nobody assigned.
    final session =
        viewModel.session ??
        (isLoading
            ? _placeholderSession()
            : ActivitySession(id: viewModel.sessionId, date: DateTime.now()));
    final entries = viewModel.entries;
    final departed = session.hasDeparted;
    final headcount = isLoading ? 3 : viewModel.participantCount;

    return LiquidPullToRefresh(
      // Keeps the dashboard on screen while it reloads, and lets go once the
      // fresh data is in rather than after a fixed delay.
      onRefresh: () => viewModel.refresh(showSkeleton: false),
      // The brand tile colour with the warm accent spinning in it: the same
      // pairing as the runner card and its button.
      color: AppColors.primaryDeep,
      backgroundColor: AppColors.accentFill,
      height: 88,
      borderWidth: 3,
      springAnimationDurationInMilliseconds: 650,
      animSpeedFactor: 1.6,
      showChildOpacityTransition: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.sm,
          AppSpace.md,
          AppSpace.huge,
        ),
        children: [
          if (modules.roster) ...[
            RosterStatusBar(session: session),
            const SizedBox(height: AppSpace.md),
          ],

          if (!isLoading && viewModel.myPendingInvites.isNotEmpty) ...[
            PendingInvitesCard(viewModel: viewModel),
            const SizedBox(height: AppSpace.sm),
          ],

          if (modules.errand) ...[
            if (session.hasArrived)
              ArrivalCard(session: session)
            else
              RunnerCard(viewModel: viewModel, session: session),
            const SizedBox(height: AppSpace.sm),
          ],

          // A pack with units but no errand still has one number to show;
          // a pack with no roster has nowhere else to say who's in.
          if (!modules.errand && modules.units)
            _FactLine(
              svgAsset: Assets.svg.roti.path,
              text: '${labels.unitCount(session.totalUnits)} to buy',
            ),
          if (!modules.roster && headcount > 0)
            _FactLine(
              svgAsset: Assets.svg.salan.path,
              text: '$headcount in the group',
            ),

          if (modules.roster) ...[
            const SizedBox(height: AppSpace.md),
            SectionHeader(
              title: "Today's roster",
              count: entries.length,
              action: modules.advisor
                  ? PillButton(
                      label: 'AI CHECK',
                      icon: Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                      onTap: () => AdvisorSheet.show(context),
                    )
                  : null,
            ),
            const SizedBox(height: AppSpace.sm),

            // Says nothing unless what was brought falls short.
            if (modules.coverage && !isLoading)
              CoverageWarning(
                headcount: headcount,
                covers: session.totalCovers,
              ),

            if (entries.isEmpty)
              RosterEmptyCard(
                name: viewModel.currentUserName,
                photoUrl: viewModel.currentUserPhotoUrl,
                onTap: departed ? null : () => AddEntrySheet.show(context),
              )
            else
              ...entries.map(
                (entry) => RosterTile(
                  entry: entry,
                  isMe: entry.userId == viewModel.currentUid,
                ),
              ),
          ],

          const SizedBox(height: AppSpace.lg),
          SectionHeader(
            title: labels.expensePluralTitle,
            count: viewModel.sharedExpenses.length,
            action: departed
                ? null
                : PillButton(
                    label: 'ADD',
                    icon: Icons.add_rounded,
                    color: AppColors.accentWarm,
                    onTap: () => ShareExpenseSheet.show(context),
                  ),
          ),
          const SizedBox(height: AppSpace.sm),

          if (viewModel.sharedExpenses.isEmpty)
            HintBanner(
              svgAsset: Assets.svg.plate.path,
              message:
                  'Splitting something with a few people? Add it here — they '
                  'get asked to confirm, and only the people who say yes get '
                  'charged.',
            )
          else
            ...viewModel.sharedExpenses.map(
              (expense) =>
                  SharedExpenseTile(expense: expense, viewModel: viewModel),
            ),
        ],
      ),
    );
  }
}

/// A single stated fact for packs that have no card to hang it on.
class _FactLine extends StatelessWidget {
  final String svgAsset;
  final String text;

  const _FactLine({required this.svgAsset, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        children: [
          AppIcon(svgAsset, size: 18),
          const SizedBox(width: AppSpace.xs),
          Text(text, style: AppText.titleSm),
        ],
      ),
    );
  }
}
