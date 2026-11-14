import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../theme/app_colors.dart';

/// One icon library, one style: Hugeicons, rounded stroke.
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size = 22, this.color = AppColors.ink, this.strokeWidth = 1.6});

  final List<List<dynamic>> icon;
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => HugeIcon(icon: icon, size: size, color: color, strokeWidth: strokeWidth);
}

/// Shortcuts so screens read well and the set stays small and consistent.
class Ic {
  Ic._();
  static const home = HugeIcons.strokeRoundedHome01;
  static const search = HugeIcons.strokeRoundedSearch01;
  static const add = HugeIcons.strokeRoundedAdd01;
  static const user = HugeIcons.strokeRoundedUserCircle;
  static const arrowRight = HugeIcons.strokeRoundedArrowRight02;
  static const arrowUpRight = HugeIcons.strokeRoundedArrowUpRight01;
  static const wallet = HugeIcons.strokeRoundedWallet01;
  static const bolt = HugeIcons.strokeRoundedFlash;
  static const news = HugeIcons.strokeRoundedNews01;
  static const sparkles = HugeIcons.strokeRoundedSparkles;
  static const chart = HugeIcons.strokeRoundedChartLineData01;
  static const bell = HugeIcons.strokeRoundedNotification01;
  static const bank = HugeIcons.strokeRoundedBank;
  static const check = HugeIcons.strokeRoundedCheckmarkCircle02;
  static const brain = HugeIcons.strokeRoundedBrain02;
  static const coins = HugeIcons.strokeRoundedCoins01;
  static const view = HugeIcons.strokeRoundedView;
  static const viewOff = HugeIcons.strokeRoundedViewOff;
  static const group = HugeIcons.strokeRoundedUserGroup;
  static const mail = HugeIcons.strokeRoundedMail01;
  static const lock = HugeIcons.strokeRoundedLockPassword;
  static const copy = HugeIcons.strokeRoundedCopy01;
  static const share = HugeIcons.strokeRoundedShare08;
  static const qr = HugeIcons.strokeRoundedQrCode;
  static const close = HugeIcons.strokeRoundedCancel01;
  static const chevronRight = HugeIcons.strokeRoundedArrowRight01;
  static const tick = HugeIcons.strokeRoundedTick02;
  static const cardAdd = HugeIcons.strokeRoundedCreditCardAdd;
  static const alert = HugeIcons.strokeRoundedAlert02;
  static const swap = HugeIcons.strokeRoundedArrowDataTransferHorizontal;
  static const swapV = HugeIcons.strokeRoundedArrowDataTransferVertical;
  static const link = HugeIcons.strokeRoundedLink01;
  static const upload = HugeIcons.strokeRoundedUpload01;
  static const chartUp = HugeIcons.strokeRoundedChartUp;
  static const settings = HugeIcons.strokeRoundedSettings02;
  static const searchOff = HugeIcons.strokeRoundedSearchRemove;
  static const pie = HugeIcons.strokeRoundedPieChart01;
  static const book = HugeIcons.strokeRoundedBookOpen01;
  static const logout = HugeIcons.strokeRoundedLogout01;
  static const info = HugeIcons.strokeRoundedInformationCircle;
  static const image = HugeIcons.strokeRoundedImage01;
  static const help = HugeIcons.strokeRoundedHelpCircle;
  static const edit = HugeIcons.strokeRoundedEdit02;
  static const file = HugeIcons.strokeRoundedFile01;
  static const paste = HugeIcons.strokeRoundedClipboard;
  static const party = HugeIcons.strokeRoundedParty;
  static const download = HugeIcons.strokeRoundedDownload01;
}
