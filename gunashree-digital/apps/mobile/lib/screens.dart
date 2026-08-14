import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_state.dart';
import 'models.dart';

const _violet = Color(0xFF6D4AFF);
const _ink = Color(0xFF17132B);
const _muted = Color(0xFF777286);

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.state});

  final AppState state;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(state: widget.state, onOpenEditor: _openEditor),
      CategoriesScreen(state: widget.state, onOpenEditor: _openEditor),
      DesignsScreen(state: widget.state, onOpenEditor: _openEditor),
      ProfileScreen(state: widget.state),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Categories'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome_mosaic_outlined),
              selectedIcon: Icon(Icons.auto_awesome_mosaic),
              label: 'My Designs'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }

  void _openEditor(PosterTemplate template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditorScreen(state: widget.state, template: template),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen(
      {super.key, required this.state, required this.onOpenEditor});

  final AppState state;
  final ValueChanged<PosterTemplate> onOpenEditor;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.state.templates
        .where((template) =>
            template.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final greeting = widget.state.userName == null
        ? 'Good morning, designer'
        : 'Good morning, ${widget.state.userName}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Row(
          children: [
            const BrandMark(size: 44),
            const Spacer(),
            IconButton(
              onPressed: () => widget.state.bootstrap(),
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'Sync templates',
            ),
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFE9E1FF),
              child: Icon(Icons.person, color: _violet),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Text(greeting,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: _muted)),
        const SizedBox(height: 4),
        Text('Make something people remember.',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        TextField(
          onChanged: (value) => setState(() => query = value),
          decoration: const InputDecoration(
            hintText: 'Search templates',
            prefixIcon: Icon(Icons.search),
            suffixIcon: Icon(Icons.tune_rounded),
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeading(title: 'Create faster', action: 'See all'),
        const SizedBox(height: 12),
        SizedBox(
          height: 126,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              QuickAction(
                label: 'Square post',
                ratio: '1:1',
                color: const Color(0xFFE9E1FF),
                icon: Icons.crop_square_rounded,
                onTap: () => _openRatioTemplate('1:1'),
              ),
              QuickAction(
                label: 'Portrait post',
                ratio: '4:5',
                color: const Color(0xFFFFE6C8),
                icon: Icons.crop_portrait_rounded,
                onTap: () => _openRatioTemplate('4:5'),
              ),
              QuickAction(
                label: 'Story',
                ratio: '9:16',
                color: const Color(0xFFD9F1E9),
                icon: Icons.phone_android_rounded,
                onTap: () => _openRatioTemplate('9:16'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeading(title: 'Fresh templates', action: 'Browse'),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No templates found',
              message: 'Try a different search.')
        else
          TemplateGrid(
              templates: filtered,
              onTap: widget.onOpenEditor,
              api: widget.state.api),
        if (widget.state.designs.isNotEmpty) ...[
          const SizedBox(height: 26),
          const SectionHeading(title: 'Recent designs', action: 'My Designs'),
          const SizedBox(height: 12),
          RecentDesignStrip(designs: widget.state.designs.take(3).toList()),
        ],
      ],
    );
  }

  void _openRatioTemplate(String ratio) {
    final match = widget.state.templates
        .where((template) => template.ratioLabel == ratio)
        .firstOrNull;
    if (match != null) widget.onOpenEditor(match);
  }
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen(
      {super.key, required this.state, required this.onOpenEditor});

  final AppState state;
  final ValueChanged<PosterTemplate> onOpenEditor;

  @override
  Widget build(BuildContext context) {
    final categoryNames = state.categories.isEmpty
        ? state.templates
            .map((template) => template.categoryName)
            .toSet()
            .toList()
        : state.categories.map((category) => category.name).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        Text('Categories', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        const Text('Find the right starting point for your next design.'),
        const SizedBox(height: 24),
        ...categoryNames.map(
          (name) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CategoryTile(
              name: name,
              count: state.templates
                  .where((template) => template.categoryName == name)
                  .length,
              onTap: () => _showCategory(context, name),
            ),
          ),
        ),
      ],
    );
  }

  void _showCategory(BuildContext context, String category) {
    final matches = state.templates
        .where((template) => template.categoryName == category)
        .toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TemplateCollectionScreen(
          title: category,
          templates: matches.isEmpty ? state.templates : matches,
          onOpenEditor: onOpenEditor,
          api: state.api,
        ),
      ),
    );
  }
}

class DesignsScreen extends StatelessWidget {
  const DesignsScreen(
      {super.key, required this.state, required this.onOpenEditor});

  final AppState state;
  final ValueChanged<PosterTemplate> onOpenEditor;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        Text('My Designs', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        const Text('Your saved work, ready for another idea.'),
        const SizedBox(height: 24),
        if (state.designs.isEmpty)
          const EmptyState(
            icon: Icons.auto_awesome_mosaic_outlined,
            title: 'Your design shelf is empty',
            message: 'Choose a template and save your first poster here.',
          )
        else
          ...state.designs.map(
            (design) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DesignListTile(design: design),
            ),
          ),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final phone = TextEditingController();
  final password = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = widget.state.isSignedIn;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        const Text('Keep your creative workspace in sync.'),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF6D4AFF), Color(0xFF9B7DFF)]),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white24,
                child: Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signedIn
                          ? (widget.state.userName ?? 'Designer')
                          : 'Guest designer',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      signedIn
                          ? 'Connected to Gunashree Digital'
                          : 'Saved designs stay on this device',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (!signedIn) ...[
          TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile number')),
          const SizedBox(height: 12),
          TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: busy ? null : _login,
            child: Text(busy ? 'Connecting…' : 'Connect account'),
          ),
          const SizedBox(height: 10),
          const Text('You can keep designing offline and connect later.',
              textAlign: TextAlign.center),
        ] else
          OutlinedButton.icon(
            onPressed: () => widget.state.signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        const SizedBox(height: 22),
        const SettingsTile(
            icon: Icons.cloud_outlined,
            title: 'Template sync',
            subtitle: 'Published templates from your studio'),
        const SettingsTile(
            icon: Icons.lock_outline,
            title: 'Privacy',
            subtitle: 'Your local drafts stay on this device'),
        const SettingsTile(
            icon: Icons.info_outline,
            title: 'About Gunashree Digital',
            subtitle: 'Independent design tools for everyday creators'),
      ],
    );
  }

  Future<void> _login() async {
    if (phone.text.trim().isEmpty || password.text.isEmpty) return;
    setState(() => busy = true);
    try {
      await widget.state.login(phone.text, password.text);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Account connected.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.state, required this.template});

  final AppState state;
  final PosterTemplate template;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final List<PosterLayer> layers;
  late Color background;
  String? selectedId;
  final picker = ImagePicker();

  PosterLayer? get selected =>
      layers.where((layer) => layer.id == selectedId).firstOrNull;

  @override
  void initState() {
    super.initState();
    layers = widget.template.layers.map((layer) => layer.copy()).toList();
    background = widget.template.background;
    selectedId = layers.isEmpty ? null : layers.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.title),
        actions: [
          IconButton(
              onPressed: _addText,
              icon: const Icon(Icons.text_fields_rounded),
              tooltip: 'Add text'),
          IconButton(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              tooltip: 'Save design'),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: Column(
                children: [
                  PosterCanvas(
                    template: widget.template,
                    layers: layers,
                    background: background,
                    selectedId: selectedId,
                    onSelect: (id) => setState(() => selectedId = id),
                    onMove: _moveLayer,
                    onResize: _resizeLayer,
                  ),
                  const SizedBox(height: 16),
                  Text(
                      'Drag elements to position them. Use the corner handle to resize.',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          EditorToolbar(
            selected: selected,
            onEditText: selected?.isText == true ? _editSelectedText : null,
            onAddPhoto: () => _pickImage('photo'),
            onAddLogo: () => _pickImage('logo'),
            onChangeFontSize: selected?.isText == true ? _changeFontSize : null,
            onChangeColor: selected?.isText == true ? _changeTextColor : null,
            onChangeBackground: _changeBackground,
          ),
        ],
      ),
    );
  }

  void _moveLayer(String id, Offset delta, double scale) {
    final layer = layers.where((item) => item.id == id).firstOrNull;
    if (layer == null || layer.locked) return;
    setState(() {
      layer.x = (layer.x + delta.dx / scale)
          .clamp(0, widget.template.width - layer.width);
      layer.y = (layer.y + delta.dy / scale)
          .clamp(0, widget.template.height - layer.height);
    });
  }

  void _resizeLayer(String id, Offset delta, double scale) {
    final layer = layers.where((item) => item.id == id).firstOrNull;
    if (layer == null || layer.locked) return;
    setState(() {
      layer.width = (layer.width + delta.dx / scale)
          .clamp(60, widget.template.width - layer.x);
      layer.height = (layer.height + delta.dy / scale)
          .clamp(44, widget.template.height - layer.y);
    });
  }

  Future<void> _addText() async {
    final controller = TextEditingController(text: 'Your message');
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add text'),
        content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration:
                const InputDecoration(hintText: 'Type something memorable')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Add')),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.trim().isEmpty) return;
    setState(() {
      final id = 'text-${DateTime.now().microsecondsSinceEpoch}';
      layers.add(PosterLayer(
          id: id,
          type: 'text',
          text: text.trim(),
          x: 80,
          y: 600,
          width: 800,
          height: 120,
          fontSize: 54,
          color: Colors.white));
      selectedId = id;
    });
  }

  Future<void> _editSelectedText() async {
    final layer = selected;
    if (layer == null) return;
    final controller = TextEditingController(text: layer.text);
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit text'),
        content:
            TextField(controller: controller, autofocus: true, maxLines: 4),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Apply')),
        ],
      ),
    );
    controller.dispose();
    if (text != null && text.trim().isNotEmpty) {
      setState(() => layer.text = text.trim());
    }
  }

  Future<void> _pickImage(String kind) async {
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (picked == null) return;
    final existing =
        layers.where((layer) => layer.isImage && layer.id == kind).firstOrNull;
    setState(() {
      if (existing != null) {
        existing.src = picked.path;
        selectedId = existing.id;
      } else {
        final id = '$kind-${DateTime.now().microsecondsSinceEpoch}';
        layers.add(PosterLayer(
            id: id,
            type: 'image',
            src: picked.path,
            x: 100,
            y: 500,
            width: 500,
            height: 420));
        selectedId = id;
      }
    });
  }

  Future<void> _changeFontSize() async {
    final layer = selected;
    if (layer == null) return;
    var value = layer.fontSize;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Font size ${value.round()}',
                  style: Theme.of(context).textTheme.titleMedium),
              Slider(
                value: value.clamp(12, 160),
                min: 12,
                max: 160,
                onChanged: (next) {
                  setSheetState(() => value = next);
                  setState(() => layer.fontSize = next);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeTextColor() async {
    final layer = selected;
    if (layer == null) return;
    await _showColorPicker(
      title: 'Text color',
      initial: layer.color,
      onColor: (color) => setState(() => layer.color = color),
    );
  }

  Future<void> _changeBackground() async {
    await _showColorPicker(
      title: 'Background',
      initial: background,
      onColor: (color) => setState(() => background = color),
    );
  }

  Future<void> _showColorPicker(
      {required String title,
      required Color initial,
      required ValueChanged<Color> onColor}) async {
    const colors = [
      Color(0xFF17132B),
      Color(0xFF6D4AFF),
      Color(0xFFFFF8F1),
      Color(0xFFF7C96F),
      Color(0xFFE8F3F0),
      Color(0xFFFFD6D6),
      Color(0xFFFFFFFF)
    ];
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              children: colors
                  .map(
                    (color) => GestureDetector(
                      onTap: () {
                        onColor(color);
                        Navigator.pop(context);
                      },
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: color,
                        child: color.toARGB32() == initial.toARGB32()
                            ? const Icon(Icons.check, color: _violet)
                            : null,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final controller = TextEditingController(text: widget.template.title);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save design'),
        content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Design name')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;
    await widget.state.saveDesign(
        template: widget.template,
        layers: layers,
        name: name,
        background: background);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Design saved to My Designs.')));
    }
  }
}

class PosterCanvas extends StatelessWidget {
  const PosterCanvas({
    super.key,
    required this.template,
    required this.layers,
    required this.background,
    required this.selectedId,
    required this.onSelect,
    required this.onMove,
    required this.onResize,
  });

  final PosterTemplate template;
  final List<PosterLayer> layers;
  final Color background;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final void Function(String id, Offset delta, double scale) onMove;
  final void Function(String id, Offset delta, double scale) onResize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / template.width;
        final height = template.height * scale;
        return Container(
          width: constraints.maxWidth,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 26,
                  offset: Offset(0, 12))
            ],
          ),
          child: Stack(
            children: [
              if (template.backgroundUrl != null &&
                  template.backgroundUrl!.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    template.backgroundUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ...layers.map((layer) => _EditorLayer(
                    layer: layer,
                    scale: scale,
                    selected: selectedId == layer.id,
                    api: null,
                    onSelect: () => onSelect(layer.id),
                    onMove: (delta) => onMove(layer.id, delta, scale),
                    onResize: (delta) => onResize(layer.id, delta, scale),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _EditorLayer extends StatelessWidget {
  const _EditorLayer({
    required this.layer,
    required this.scale,
    required this.selected,
    required this.api,
    required this.onSelect,
    required this.onMove,
    required this.onResize,
  });

  final PosterLayer layer;
  final double scale;
  final bool selected;
  final dynamic api;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onMove;
  final ValueChanged<Offset> onResize;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: layer.x * scale,
      top: layer.y * scale,
      width: layer.width * scale,
      height: layer.height * scale,
      child: GestureDetector(
        onTap: onSelect,
        onPanStart: (_) => onSelect(),
        onPanUpdate: layer.locked ? null : (details) => onMove(details.delta),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: _layerContent()),
            if (selected && !layer.locked)
              Positioned(
                right: -7,
                bottom: -7,
                child: GestureDetector(
                  onPanUpdate: (details) => onResize(details.delta),
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                        color: _violet,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.white, width: 2)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _layerContent() {
    if (layer.isImage && layer.src.isNotEmpty) {
      final image = layer.src.startsWith('http')
          ? Image.network(layer.src, fit: BoxFit.cover)
          : Image.file(File(layer.src), fit: BoxFit.cover);
      return ClipRRect(borderRadius: BorderRadius.circular(12), child: image);
    }
    if (layer.isImage) {
      return DecoratedBox(
        decoration: BoxDecoration(
            color: Colors.black12, borderRadius: BorderRadius.circular(12)),
        child: const Center(
            child: Icon(Icons.add_a_photo_outlined, color: Colors.black45)),
      );
    }
    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        layer.text,
        style: TextStyle(
            fontSize: layer.fontSize * scale,
            height: 1.04,
            fontWeight: FontWeight.w800,
            color: layer.color),
      ),
    );
  }
}

class EditorToolbar extends StatelessWidget {
  const EditorToolbar({
    super.key,
    required this.selected,
    required this.onEditText,
    required this.onAddPhoto,
    required this.onAddLogo,
    required this.onChangeFontSize,
    required this.onChangeColor,
    required this.onChangeBackground,
  });

  final PosterLayer? selected;
  final VoidCallback? onEditText;
  final VoidCallback onAddPhoto;
  final VoidCallback onAddLogo;
  final VoidCallback? onChangeFontSize;
  final VoidCallback? onChangeColor;
  final VoidCallback onChangeBackground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Row(
            children: [
              ToolButton(
                  icon: Icons.text_fields_rounded,
                  label: 'Text',
                  onTap: onEditText),
              ToolButton(
                  icon: Icons.photo_outlined,
                  label: 'Photo',
                  onTap: onAddPhoto),
              ToolButton(
                  icon: Icons.badge_outlined, label: 'Logo', onTap: onAddLogo),
              ToolButton(
                  icon: Icons.format_size_rounded,
                  label: 'Size',
                  onTap: onChangeFontSize),
              ToolButton(
                  icon: Icons.palette_outlined,
                  label: 'Color',
                  onTap: onChangeColor),
              ToolButton(
                  icon: Icons.format_color_fill_outlined,
                  label: 'Background',
                  onTap: onChangeBackground),
              if (selected != null) ...[
                const SizedBox(width: 8),
                Text(selected!.isText ? 'Text selected' : 'Image selected',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: _muted)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ToolButton extends StatelessWidget {
  const ToolButton(
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: onTap == null ? 0.38 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: _ink),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: _ink,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TemplateGrid extends StatelessWidget {
  const TemplateGrid(
      {super.key,
      required this.templates,
      required this.onTap,
      required this.api});

  final List<PosterTemplate> templates;
  final ValueChanged<PosterTemplate> onTap;
  final dynamic api;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: templates.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.76),
      itemBuilder: (context, index) => TemplateCard(
          template: templates[index],
          onTap: () => onTap(templates[index]),
          api: api),
    );
  }
}

class TemplateCard extends StatelessWidget {
  const TemplateCard(
      {super.key,
      required this.template,
      required this.onTap,
      required this.api});

  final PosterTemplate template;
  final VoidCallback onTap;
  final dynamic api;

  @override
  Widget build(BuildContext context) {
    final imageUrl = template.thumbnailUrl;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                  color: template.background,
                  borderRadius: BorderRadius.circular(20)),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          MiniPoster(template: template))
                  : MiniPoster(template: template),
            ),
          ),
          const SizedBox(height: 8),
          Text(template.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 2),
          Text(template.ratioLabel,
              style: const TextStyle(fontSize: 12, color: _muted)),
        ],
      ),
    );
  }
}

class MiniPoster extends StatelessWidget {
  const MiniPoster({super.key, required this.template});

  final PosterTemplate template;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: template.layers
          .take(3)
          .map(
            (layer) => Positioned(
              left: layer.x / template.width * 160,
              top: layer.y / template.height * 220,
              right: 10,
              child: Text(
                layer.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: (layer.fontSize / 6).clamp(8, 22),
                    color: layer.color,
                    fontWeight: FontWeight.w800,
                    height: 1),
              ),
            ),
          )
          .toList(),
    );
  }
}

class TemplateCollectionScreen extends StatelessWidget {
  const TemplateCollectionScreen(
      {super.key,
      required this.title,
      required this.templates,
      required this.onOpenEditor,
      required this.api});

  final String title;
  final List<PosterTemplate> templates;
  final ValueChanged<PosterTemplate> onOpenEditor;
  final dynamic api;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TemplateGrid(templates: templates, onTap: onOpenEditor, api: api)
        ],
      ),
    );
  }
}

class QuickAction extends StatelessWidget {
  const QuickAction(
      {super.key,
      required this.label,
      required this.ratio,
      required this.color,
      required this.icon,
      required this.onTap});

  final String label;
  final String ratio;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 136,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(20)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: _ink),
            const Spacer(),
            Text(ratio,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, color: _ink)),
            Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
          ]),
        ),
      ),
    );
  }
}

class RecentDesignStrip extends StatelessWidget {
  const RecentDesignStrip({super.key, required this.designs});

  final List<LocalDesign> designs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: designs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) => Container(
          width: 100,
          decoration: BoxDecoration(
              color: designs[index].background,
              borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.all(10),
          child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(designs[index].name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: _ink))),
        ),
      ),
    );
  }
}

class DesignListTile extends StatelessWidget {
  const DesignListTile({super.key, required this.design});

  final LocalDesign design;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAE7F2))),
      child: Row(
        children: [
          Container(
              width: 72,
              height: 88,
              decoration: BoxDecoration(
                  color: design.background,
                  borderRadius: BorderRadius.circular(14)),
              child: MiniDesign(design: design)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(design.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: _ink)),
                const SizedBox(height: 5),
                Text(design.templateTitle,
                    style: const TextStyle(color: _muted)),
                const SizedBox(height: 5),
                Text(_formatDate(design.updatedAt),
                    style: const TextStyle(fontSize: 12, color: _muted))
              ])),
          const Icon(Icons.chevron_right_rounded, color: _muted),
        ],
      ),
    );
  }
}

class MiniDesign extends StatelessWidget {
  const MiniDesign({super.key, required this.design});

  final LocalDesign design;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: design.layers
          .take(2)
          .map(
            (layer) => Positioned(
              left: 6,
              top: (layer.y / 18).clamp(4, 68),
              right: 4,
              child: Text(
                layer.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: (layer.fontSize / 7).clamp(6, 13),
                  fontWeight: FontWeight.w800,
                  color: layer.color,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile(
      {super.key,
      required this.name,
      required this.count,
      required this.onTap});

  final String name;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEAE7F2))),
        child: Row(children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: const Color(0xFFE9E1FF),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.auto_awesome, color: _violet)),
          const SizedBox(width: 14),
          Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: _ink))),
          Text('$count templates', style: const TextStyle(color: _muted)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: _muted)
        ]),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 5),
        leading: CircleAvatar(
            backgroundColor: const Color(0xFFEDE9F8),
            foregroundColor: _violet,
            child: Icon(icon)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
        subtitle: Text(subtitle));
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const Spacer(),
      Text(action,
          style: const TextStyle(color: _violet, fontWeight: FontWeight.w700))
    ]);
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEAE7F2))),
      child: Column(children: [
        Icon(icon, size: 38, color: _violet),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center)
      ]),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_violet, Color(0xFFB19AFF)]),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(Icons.auto_awesome_rounded,
          color: Colors.white, size: size * 0.52),
    );
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
