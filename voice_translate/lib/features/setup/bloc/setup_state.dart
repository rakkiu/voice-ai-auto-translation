import 'package:equatable/equatable.dart';

enum SetupStatus { initial, checkingModels, copyingModels, loadingModels, ready, error }

class SetupState extends Equatable {
  const SetupState({
    this.status = SetupStatus.initial,
    this.progress,
    this.progressMessage,
    this.errorMessage,
  });

  final SetupStatus status;
  final double? progress;
  final String? progressMessage;
  final String? errorMessage;

  bool get allReady => status == SetupStatus.ready;

  SetupState copyWith({
    SetupStatus? status,
    double? progress,
    String? progressMessage,
    String? errorMessage,
  }) =>
      SetupState(
        status: status ?? this.status,
        progress: progress ?? this.progress,
        progressMessage: progressMessage ?? this.progressMessage,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [
        status,
        progress,
        progressMessage,
        errorMessage,
      ];
}
