const fs = require('fs');
const hs = fs.readFileSync('lib/screens/home_screen.dart', 'utf-8');
const ad = fs.readFileSync('lib/widgets/app_drawer.dart', 'utf-8');

const hsDrawerItemsMatch = hs.match(/(ListView\(\s*padding:\s*EdgeInsets\.zero,\s*children:\s*\[[\s\S]*?padding:\s*const EdgeInsets\.all\(16\)[\s\S]*?\]\s*,?\s*\)\s*,?\s*\)\s*,?\s*\]\s*,?\s*\)\s*,?\s*)/);

if (!hsDrawerItemsMatch) {
  console.log('hs drawer items match failed');
  process.exit(1);
}
let drawerBody = hsDrawerItemsMatch[1];
// Close SafeArea cleanly
drawerBody = drawerBody + '      );\n  }\n';

// now we inject Finance Dashboard into drawerBody
const fDash = `
                  _buildDrawerItem(
                    icon: Icons.attach_money,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Finance Dashboard',
                    subtitle: 'Financial overview',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FinanceDashboardScreen(),
                        ),
                      );
                    },
                  ),
`;
drawerBody = drawerBody.replace("_buildDrawerItem(\n                    icon: Icons.bar_chart_rounded,", fDash + "_buildDrawerItem(\n                    icon: Icons.bar_chart_rounded,");

// Also remove agricultural_news_screen because the previous file used `AgriculturalNewsScreen()` (no const) but the import might be different. Let's just trust it works or dart analyze will fail.

// replace new expanded matching ad
// In app_drawer, we want to replace from `ListView(` all the way down to `Widget _buildDrawerSection(`
let adFinal = ad.replace(/ListView\([\s\S]*?Widget _buildDrawerSection/, drawerBody + '\n  Widget _buildDrawerSection');

// remove _buildExpansionDrawerItem and _buildDrawerSubItem since they are not used anymore
adFinal = adFinal.replace(/Widget _buildExpansionDrawerItem[\s\S]*/, '}');

fs.writeFileSync('lib/widgets/app_drawer.dart', adFinal);
console.log('done!');
