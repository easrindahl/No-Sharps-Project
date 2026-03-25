import 'package:flutter/material.dart';
import 'views/account_view.dart';
import 'views/home_view.dart';
import 'views/map_view.dart';
import 'views/safety_view.dart';

class NavigationShell extends StatefulWidget {
	const NavigationShell({super.key});

	@override
	State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
	int _selectedIndex = 0;

	static const List<Widget> _pages = [
		HomeView(),
		MapView(),
		SafetyView(),
		AccountView(),
	];

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: _pages[_selectedIndex],
			bottomNavigationBar: BottomNavigationBar(
				currentIndex: _selectedIndex,
				type: BottomNavigationBarType.fixed,
				onTap: (index) {
					setState(() {
						_selectedIndex = index;
					});
				},
				items: const [
					BottomNavigationBarItem(
						icon: Icon(Icons.home_outlined),
						activeIcon: Icon(Icons.home),
						label: 'Home',
					),
					BottomNavigationBarItem(
						icon: Icon(Icons.map_outlined),
						activeIcon: Icon(Icons.map),
						label: 'Map',
					),
					BottomNavigationBarItem(
						icon: Icon(Icons.shield_outlined),
						activeIcon: Icon(Icons.shield),
						label: 'Safety',
					),
					BottomNavigationBarItem(
						icon: Icon(Icons.person_outline),
						activeIcon: Icon(Icons.person),
						label: 'Account',
					),
				],
			),
		);
	}
}
