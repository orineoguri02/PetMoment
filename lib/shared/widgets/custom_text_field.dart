import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/index.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final bool isPassword;
  final bool isRequired;
  final bool isEnabled;
  final bool isReadOnly;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final String? Function(String?)? validator;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final double? borderWidth;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final TextAlign? textAlign;
  
  const CustomTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.isPassword = false,
    this.isRequired = false,
    this.isEnabled = true,
    this.isReadOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.validator,
    this.contentPadding,
    this.fillColor,
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    this.textStyle,
    this.hintStyle,
    this.labelStyle,
    this.textAlign,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isObscured = true;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Row(
            children: [
              Text(
                widget.labelText!,
                style: widget.labelStyle ?? AppTextStyles.label,
              ),
              if (widget.isRequired)
                Text(
                  ' *',
                  style: TextStyle(color: AppColors.error),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.isEnabled,
          readOnly: widget.isReadOnly,
          obscureText: widget.isPassword ? _isObscured : false,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          textAlign: widget.textAlign ?? TextAlign.start,
          style: widget.textStyle ?? AppTextStyles.bodyMedium,
          validator: widget.validator,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onEditingComplete: widget.onEditingComplete,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: widget.hintStyle ?? AppTextStyles.hint,
            errorText: widget.errorText,
            filled: true,
            fillColor: widget.fillColor ?? Colors.grey[50],
            contentPadding: widget.contentPadding ?? 
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                  )
                : widget.suffixIcon,
            border: OutlineInputBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.borderColor ?? AppColors.textSecondary,
                width: widget.borderWidth ?? 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.borderColor ?? AppColors.textSecondary,
                width: widget.borderWidth ?? 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: widget.borderWidth ?? 1,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.error,
                width: widget.borderWidth ?? 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.error,
                width: widget.borderWidth ?? 1,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.buttonDisabled,
                width: widget.borderWidth ?? 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomSearchTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool isEnabled;
  final FocusNode? focusNode;
  
  const CustomSearchTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.isEnabled = true,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: isEnabled,
      style: AppTextStyles.bodyMedium,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText ?? '검색',
        hintStyle: AppTextStyles.hint,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: controller?.text.isNotEmpty == true
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: onClear ?? () {
                  controller?.clear();
                  onChanged?.call('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

class CustomMultilineTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final bool isRequired;
  final bool isEnabled;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  
  const CustomMultilineTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.isRequired = false,
    this.isEnabled = true,
    this.minLines = 3,
    this.maxLines = 5,
    this.maxLength,
    this.onChanged,
    this.validator,
    this.contentPadding,
    this.fillColor,
    this.borderColor,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Row(
            children: [
              Text(
                labelText!,
                style: AppTextStyles.label,
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(color: AppColors.error),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          enabled: isEnabled,
          minLines: minLines,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          style: AppTextStyles.bodyMedium,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.hint,
            errorText: errorText,
            filled: true,
            fillColor: fillColor ?? Colors.grey[50],
            contentPadding: contentPadding ?? 
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(8),
              borderSide: BorderSide(
                color: borderColor ?? AppColors.textSecondary,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(8),
              borderSide: BorderSide(
                color: borderColor ?? AppColors.textSecondary,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 1,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.error,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
} 