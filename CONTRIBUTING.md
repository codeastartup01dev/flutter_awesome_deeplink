# Contributing to Flutter Awesome Deeplink

Thank you for your interest in contributing to Flutter Awesome Deeplink! We welcome contributions from the community and are grateful for your help in making this plugin better.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.3.0)
- Dart SDK (>=3.0.0)
- Android Studio or VS Code with Flutter extensions
- Git

### Development Setup

1. **Fork the repository**
   ```bash
   git clone https://github.com/yourusername/flutter_awesome_deeplink.git
   cd flutter_awesome_deeplink
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   cd example && flutter pub get
   ```

3. **Run the example app**
   ```bash
   cd example
   flutter run
   ```

## 📋 How to Contribute

### Reporting Issues

Before creating an issue, please:

1. **Search existing issues** to avoid duplicates
2. **Use the issue templates** when available
3. **Provide detailed information**:
   - Flutter version (`flutter --version`)
   - Platform (Android/iOS/Web)
   - Plugin version
   - Minimal reproduction code
   - Expected vs actual behavior

### Suggesting Features

We welcome feature suggestions! Please:

1. **Check existing feature requests** first
2. **Describe the use case** clearly
3. **Explain the expected behavior**
4. **Consider backward compatibility**

### Code Contributions

#### Before You Start

1. **Create an issue** to discuss major changes
2. **Check the roadmap** to avoid conflicts
3. **Follow the coding standards** below

#### Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write clean, documented code
   - Add tests for new functionality
   - Update documentation as needed

3. **Test your changes**
   ```bash
   # Run tests
   flutter test
   
   # Test with example app
   cd example && flutter run
   
   # Test on multiple platforms
   flutter run -d android
   flutter run -d ios
   flutter run -d chrome
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   ```

5. **Push and create a pull request**
   ```bash
   git push origin feature/your-feature-name
   ```

## 🎯 Coding Standards

### Dart Code Style

- **Follow Flutter/Dart conventions**
- **Use meaningful variable names**
- **Add comprehensive comments**
- **Format code**: `dart format .`
- **Analyze code**: `dart analyze`

### Documentation

- **Document all public APIs**
- **Include usage examples**
- **Update README for new features**
- **Add inline comments for complex logic**

### Testing

- **Write unit tests** for new functionality
- **Test on multiple platforms**
- **Include integration tests** for critical paths
- **Maintain test coverage** above 80%

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` new features
- `fix:` bug fixes
- `docs:` documentation changes
- `style:` formatting changes
- `refactor:` code refactoring
- `test:` adding tests
- `chore:` maintenance tasks

Examples:
```
feat: add iOS clipboard detection for deferred links
fix: resolve Android Install Referrer timeout issue
docs: update README with logger integration examples
```

## 🧪 Testing Guidelines

### Unit Tests

- Test all public methods
- Mock external dependencies
- Test error conditions
- Verify callback behavior

### Integration Tests

- Test complete attribution flows
- Verify platform-specific behavior
- Test configuration options
- Validate error handling

### Manual Testing

- Test on real devices
- Verify deep link navigation
- Test attribution accuracy
- Check privacy compliance

## 📚 Documentation Guidelines

### Code Documentation

```dart
/// Brief description of the method
///
/// **Parameters**:
/// - `param1`: Description of parameter
/// 
/// **Returns**: Description of return value
///
/// **Example**:
/// ```dart
/// final result = methodName(param1: 'value');
/// ```
///
/// **Throws**: Exception conditions
```

### README Updates

- Keep examples up to date
- Add new configuration options
- Update success rate statistics
- Include migration guides

## 🔍 Code Review Process

### Pull Request Requirements

- [ ] **Clear description** of changes
- [ ] **Tests included** for new functionality
- [ ] **Documentation updated**
- [ ] **No breaking changes** (or clearly marked)
- [ ] **Passes all CI checks**

### Review Criteria

- **Code quality** and readability
- **Performance impact**
- **Security considerations**
- **Backward compatibility**
- **Test coverage**

## 🏗️ Architecture Guidelines

### Plugin Structure

```
lib/
├── src/
│   ├── models/          # Data models and configurations
│   ├── services/        # Core business logic
│   └── utils/           # Helper utilities
└── flutter_awesome_deeplink.dart  # Public API
```

### Design Principles

- **Single Responsibility**: Each class has one clear purpose
- **Dependency Injection**: Use constructor injection
- **Error Handling**: Comprehensive error handling with meaningful messages
- **Privacy First**: Minimal data collection, opt-in features
- **Platform Optimization**: Use platform-specific best practices

## 🚀 Release Process

### Version Numbering

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Checklist

- [ ] Update version in `pubspec.yaml`
- [ ] Update `CHANGELOG.md`
- [ ] Update documentation
- [ ] Test on all platforms
- [ ] Create release notes
- [ ] Tag release in Git

## 🤝 Community Guidelines

### Code of Conduct

- **Be respectful** and inclusive
- **Help others** learn and grow
- **Provide constructive feedback**
- **Follow project guidelines**

### Communication

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and community chat
- **Pull Requests**: Code contributions and reviews

## 📞 Getting Help

If you need help contributing:

1. **Check existing documentation**
2. **Search GitHub issues and discussions**
3. **Create a new discussion** for questions
4. **Reach out to maintainers** for complex issues

## 🙏 Recognition

Contributors are recognized in:

- **README.md** contributors section
- **Release notes** for significant contributions
- **GitHub contributors** page

Thank you for contributing to Flutter Awesome Deeplink! 🚀

---

**Happy Coding!** 💻✨
