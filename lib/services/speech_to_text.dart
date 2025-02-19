import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextService {
  final SpeechToText speech = SpeechToText();
  bool _hasSpeech = false;
  double level = 0.0;
  String lastWords = '';
  String lastError = '';
  String lastStatus = '';
  List<LocaleName> _localeNames = [];

  Future<void> initSpeechState(Function(String) errorListener, Function(String) statusListener, Function(String) logEvent) async {
    logEvent('Initialize');
    try {
      var hasSpeech = await speech.initialize(
        onError: (error) => errorListener(error.errorMsg),
        onStatus: (status) => statusListener(status),
        debugLogging: false,
      );
      if (hasSpeech) {
        _localeNames = await speech.locales();
        var systemLocale = await speech.systemLocale();
      }
      _hasSpeech = hasSpeech;
    } catch (e) {
      lastError = 'Speech recognition failed: ${e.toString()}';
      _hasSpeech = false;
    }
  }

  void startListening(Function(SpeechRecognitionResult) resultListener, Function(double) soundLevelListener, Function(String) logEvent) {
    logEvent('start listening');
    lastWords = '';
    lastError = '';
    speech.listen(
      onResult: resultListener,
      listenFor: Duration(seconds: 30),
      pauseFor: Duration(seconds: 3),
      localeId: '',
      onSoundLevelChange: soundLevelListener,
      listenMode: ListenMode.confirmation,
    );
  }

  void stopListening(Function(String) logEvent) {
    logEvent('stop');
    speech.stop();
    level = 0.0;
  }

  void cancelListening(Function(String) logEvent) {
    logEvent('cancel');
    speech.cancel();
    level = 0.0;
  }

  String processSpeechResult(String recognizedWords) {
    final Map<String, String> numberWords = {
      'zero': '0',
      'one': '1',
      'two': '2',
      'three': '3',
      'four': '4',
      'five': '5',
      'six': '6',
      'seven': '7',
      'eight': '8',
      'nine': '9',
      'ten': '10',
      'eleven': '11',
      'twelve': '12',
      'thirteen': '13',
      'fourteen': '14',
      'fifteen': '15',
      'sixteen': '16',
      'seventeen': '17',
      'eighteen': '18',
      'nineteen': '19',
      'twenty': '20',
      'thirty': '30',
      'forty': '40',
      'fifty': '50',
      'sixty': '60',
      'seventy': '70',
      'eighty': '80',
      'ninety': '90',
      'hundred': '100',
      'thousand': '1000',
      'million': '1000000',
      'billion': '1000000000',
    };

    List<String> words = recognizedWords.toLowerCase().split(' ');

    List<String> processedWords = [];
    for (String word in words) {
      if (numberWords.containsKey(word)) {
        processedWords.add(numberWords[word]!);
      } else if (word == 'dot' || word == 'point') {
        processedWords.add('.');
      } else if (word == 'slash' || word == 'over') {
        processedWords.add('/');
      } else {
        // Remove non-numeric characters from the word
        String numericWord = word.replaceAll(RegExp(r'[^0-9./]'), '');
        if (numericWord.isNotEmpty) {
          processedWords.add(numericWord);
        }
      }
    }

    String joinedWords = processedWords.join('');
    joinedWords = joinedWords.replaceFirst('.', '#').replaceAll('.', '').replaceFirst('#', '.');
    joinedWords = joinedWords.replaceFirst('/', '#').replaceAll('/', '').replaceFirst('#', '/');

    return joinedWords;
  }
}