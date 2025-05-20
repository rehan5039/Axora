import 'package:flutter/material.dart';
import 'package:axora/models/challenge.dart';
import 'package:axora/services/challenge_service.dart';
import 'package:axora/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AddEditChallengeScreen extends StatefulWidget {
  final Challenge? challenge;

  const AddEditChallengeScreen({
    Key? key,
    this.challenge,
  }) : super(key: key);

  @override
  State<AddEditChallengeScreen> createState() => _AddEditChallengeScreenState();
}

class _AddEditChallengeScreenState extends State<AddEditChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _challengeService = ChallengeService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _buttonTextController = TextEditingController();
  
  ChallengeType _selectedType = ChallengeType.meditation;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  
  List<String> _pollOptions = ['Option 1', 'Option 2'];
  bool _isLoading = false;
  bool _isMultiSelectPoll = false;
  
  // Quiz questions
  List<Map<String, dynamic>> _quizQuestions = [
    {
      'question': 'Question 1',
      'options': ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
      'correctAnswer': 0,
    }
  ];
  
  @override
  void initState() {
    super.initState();
    
    if (widget.challenge != null) {
      // Editing existing challenge
      _titleController.text = widget.challenge!.title;
      _descriptionController.text = widget.challenge!.description;
      _selectedType = widget.challenge!.type;
      _startDate = widget.challenge!.startDate;
      _endDate = widget.challenge!.endDate;
      _buttonTextController.text = widget.challenge!.buttonText;
      _isMultiSelectPoll = widget.challenge!.isMultiSelect;
      
      if (widget.challenge!.type == ChallengeType.meditation) {
        _durationController.text = widget.challenge!.durationMinutes.toString();
      }
      
      if (widget.challenge!.type == ChallengeType.poll && 
          widget.challenge!.pollOptions != null && 
          widget.challenge!.pollOptions!.isNotEmpty) {
        _pollOptions = widget.challenge!.pollOptions!.keys.toList();
      }
      
      if (widget.challenge!.type == ChallengeType.quiz && 
          widget.challenge!.quizQuestions != null && 
          widget.challenge!.quizQuestions!.isNotEmpty) {
        _quizQuestions = widget.challenge!.quizQuestions!;
      }
    } else {
      // Default values for new challenge
      _durationController.text = '5';
      _buttonTextController.text = 'Complete Challenge';
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _buttonTextController.dispose();
    super.dispose();
  }
  
  Future<void> _saveChallenge() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      
      // Prepare poll options if needed
      Map<String, int>? pollOptions;
      if (_selectedType == ChallengeType.poll) {
        pollOptions = {};
        for (final option in _pollOptions) {
          pollOptions[option] = 0;
        }
      }
      
      // Prepare quiz questions if needed
      List<Map<String, dynamic>>? quizQuestions;
      if (_selectedType == ChallengeType.quiz) {
        quizQuestions = _quizQuestions;
      }
      
      final challenge = Challenge(
        id: widget.challenge?.id ?? 'temp_id',
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
        startDate: _startDate,
        endDate: _endDate,
        durationMinutes: _selectedType == ChallengeType.meditation ? 
            int.tryParse(_durationController.text) ?? 5 : 0,
        pollOptions: pollOptions,
        quizQuestions: quizQuestions,
        createdBy: userId,
        isMultiSelect: _selectedType == ChallengeType.poll ? _isMultiSelectPoll : false,
        buttonText: _buttonTextController.text,
      );
      
      if (widget.challenge == null) {
        // Create new challenge
        await _challengeService.createChallenge(challenge);
      } else {
        // Update existing challenge (not implemented in this demo)
        // TODO: Implement update functionality in ChallengeService
        await _challengeService.createChallenge(challenge);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving challenge: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save challenge: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : _endDate;
    final firstDate = isStartDate ? DateTime.now() : _startDate;
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          // Ensure end date is after start date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }
  
  void _addPollOption() {
    setState(() {
      _pollOptions.add('Option ${_pollOptions.length + 1}');
    });
  }
  
  void _updatePollOption(int index, String value) {
    setState(() {
      _pollOptions[index] = value;
    });
  }
  
  void _removePollOption(int index) {
    if (_pollOptions.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poll must have at least 2 options'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _pollOptions.removeAt(index);
    });
  }

  void _addQuizQuestion() {
    setState(() {
      _quizQuestions.add({
        'question': 'New Question',
        'options': ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
        'correctAnswer': 0,
      });
    });
  }
  
  void _removeQuizQuestion(int index) {
    if (_quizQuestions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz must have at least 1 question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _quizQuestions.removeAt(index);
    });
  }
  
  void _updateQuizQuestion(int questionIndex, String question) {
    setState(() {
      _quizQuestions[questionIndex]['question'] = question;
    });
  }
  
  void _updateQuizOption(int questionIndex, int optionIndex, String option) {
    setState(() {
      (_quizQuestions[questionIndex]['options'] as List)[optionIndex] = option;
    });
  }
  
  void _setCorrectAnswer(int questionIndex, int correctAnswerIndex) {
    setState(() {
      _quizQuestions[questionIndex]['correctAnswer'] = correctAnswerIndex;
    });
  }
  
  void _addQuizOption(int questionIndex) {
    final options = _quizQuestions[questionIndex]['options'] as List;
    if (options.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 6 options per question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      options.add('New Option');
    });
  }
  
  void _removeQuizOption(int questionIndex, int optionIndex) {
    final options = _quizQuestions[questionIndex]['options'] as List;
    if (options.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question must have at least 2 options'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      options.removeAt(optionIndex);
      
      // If removed option was the correct answer, reset to first option
      if (_quizQuestions[questionIndex]['correctAnswer'] == optionIndex) {
        _quizQuestions[questionIndex]['correctAnswer'] = 0;
      } else if (_quizQuestions[questionIndex]['correctAnswer'] > optionIndex) {
        // Adjust the correct answer index if it was after the removed option
        _quizQuestions[questionIndex]['correctAnswer'] = 
            (_quizQuestions[questionIndex]['correctAnswer'] as int) - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.challenge == null ? 'Add Challenge' : 'Edit Challenge'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Challenge type selector
                    Text(
                      'Challenge Type',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<ChallengeType>(
                      segments: const [
                        ButtonSegment(
                          value: ChallengeType.meditation,
                          label: Text('Meditation'),
                          icon: Icon(Icons.self_improvement),
                        ),
                        ButtonSegment(
                          value: ChallengeType.poll,
                          label: Text('Poll'),
                          icon: Icon(Icons.poll),
                        ),
                        ButtonSegment(
                          value: ChallengeType.task,
                          label: Text('Task'),
                          icon: Icon(Icons.task_alt),
                        ),
                        ButtonSegment(
                          value: ChallengeType.quiz,
                          label: Text('Quiz'),
                          icon: Icon(Icons.quiz),
                        ),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (Set<ChallengeType> newSelection) {
                        setState(() {
                          _selectedType = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Add multi-select option for polls
                    if (_selectedType == ChallengeType.poll) ...[
                      Row(
                        children: [
                          Checkbox(
                            value: _isMultiSelectPoll,
                            onChanged: (value) {
                              setState(() {
                                _isMultiSelectPoll = value ?? false;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Allow multiple selections',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Challenge details
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _buttonTextController,
                      decoration: const InputDecoration(
                        labelText: 'Button Text',
                        border: OutlineInputBorder(),
                        hintText: 'Text displayed on the action button',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter button text';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Duration (only for meditation challenges)
                    if (_selectedType == ChallengeType.meditation) ...[
                      Text(
                        'Meditation Duration (minutes)',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          suffixText: 'minutes',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter duration';
                          }
                          final duration = int.tryParse(value);
                          if (duration == null || duration <= 0) {
                            return 'Please enter a valid duration';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Poll options (only for poll challenges)
                    if (_selectedType == ChallengeType.poll) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Poll Options',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Option'),
                            onPressed: _addPollOption,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_pollOptions.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: _pollOptions[index],
                                  decoration: InputDecoration(
                                    labelText: 'Option ${index + 1}',
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (value) => _updatePollOption(index, value),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter option text';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.red,
                                onPressed: () => _removePollOption(index),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                    
                    // Quiz questions (only for quiz challenges)
                    if (_selectedType == ChallengeType.quiz) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Quiz Questions',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Question'),
                            onPressed: _addQuizQuestion,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      ...List.generate(_quizQuestions.length, (questionIndex) {
                        final question = _quizQuestions[questionIndex];
                        final options = question['options'] as List;
                        final correctAnswer = question['correctAnswer'] as int;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Question ${questionIndex + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeQuizQuestion(questionIndex),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: question['question'] as String,
                                  decoration: const InputDecoration(
                                    labelText: 'Question',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) => _updateQuizQuestion(questionIndex, value),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a question';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Text(
                                      'Options',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Add Option'),
                                      onPressed: () => _addQuizOption(questionIndex),
                                    ),
                                  ],
                                ),
                                
                                ...List.generate(options.length, (optionIndex) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Radio<int>(
                                          value: optionIndex,
                                          groupValue: correctAnswer,
                                          onChanged: (value) {
                                            if (value != null) {
                                              _setCorrectAnswer(questionIndex, value);
                                            }
                                          },
                                        ),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: options[optionIndex] as String,
                                            decoration: InputDecoration(
                                              labelText: 'Option ${optionIndex + 1}',
                                              border: const OutlineInputBorder(),
                                              contentPadding: const EdgeInsets.symmetric(
                                                vertical: 8,
                                                horizontal: 12,
                                              ),
                                            ),
                                            onChanged: (value) => _updateQuizOption(
                                              questionIndex,
                                              optionIndex,
                                              value,
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter option text';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                          onPressed: () => _removeQuizOption(questionIndex, optionIndex),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Select the correct answer by clicking the radio button',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                    
                    // Date range
                    Text(
                      'Challenge Period',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat('MMM d, yyyy').format(_startDate),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat('MMM d, yyyy').format(_endDate),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveChallenge,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.challenge == null ? 'Create Challenge' : 'Update Challenge',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 