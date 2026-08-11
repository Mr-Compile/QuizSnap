# QuizSnap Testing Checklist

This checklist covers all the fixes and improvements implemented for the QuizSnap Flutter application.

## 1. AI Generation & Riverpod Initialization Bug

### Tests:
- [ ] **API Key Save/Load**
  - [ ] Enter API key in AI Generate screen
  - [ ] Verify API key is saved to secure storage
  - [ ] Restart app and verify API key is loaded automatically
  - [ ] Verify no Riverpod/provider error on first load

- [ ] **Provider Initialization**
  - [ ] Verify GroqProvider initializes immediately after saving API key
  - [ ] Verify loading state is shown during initialization
  - [ ] Verify no navigation away is needed to refresh state
  - [ ] Verify null API key is handled safely

- [ ] **Model Selection**
  - [ ] Verify model selector appears in Settings
  - [ ] Verify default model is `llama-3.1-8b-instant`
  - [ ] Verify model can be changed in Settings
  - [ ] Verify selected model persists across app restarts

- [ ] **Model Fallback**
  - [ ] Test with invalid/unavailable Groq model
  - [ ] Verify automatic fallback to supported model
  - [ ] Verify user-friendly error message is shown
  - [ ] Verify AI generation continues with fallback model

### Expected Results:
- No Riverpod/provider errors on AI screen
- API key persists and loads automatically
- Model selection works correctly
- Graceful fallback for invalid models

---

## 2. Analytics Riverpod Type Error

### Tests:
- [ ] **Deck Accuracy Calculations**
  - [ ] Navigate to Subject Accuracy screen
  - [ ] Verify no "type 'dynamic' is not a subtype of type 'double'" error
  - [ ] Verify accuracy percentages display correctly
  - [ ] Verify chart data receives proper double values

- [ ] **Mastery Distribution**
  - [ ] Navigate to Mastery Breakdown screen
  - [ ] Verify percentage calculations are correct
  - [ ] Verify no type conversion errors

- [ ] **Daily Activity Charts**
  - [ ] Navigate to Daily Activity screen
  - [ ] Verify chart data loads without type errors
  - [ ] Verify accuracy calculations use proper double casting

- [ ] **Improvement Trends**
  - [ ] Verify trend calculations use proper type casting
  - [ ] Verify no dynamic map issues in calculations

### Expected Results:
- No type errors in analytics screens
- All calculations use strongly typed values
- Charts display correctly with proper data types

---

## 3. Cached PDF/TXT Permission Issue

### Tests:
- [ ] **File Import Flow**
  - [ ] Import PDF file
  - [ ] Verify file is copied to app-private storage
  - [ ] Verify success snackbar is shown
  - [ ] Close and reopen app
  - [ ] Verify cached document can be opened without permission request

- [ ] **TXT Import**
  - [ ] Import TXT file
  - [ ] Verify file is copied to app-private storage
  - [ ] Verify text extraction works
  - [ ] Verify cached document can be reopened without permission

- [ ] **Permission Fallback**
  - [ ] Test with permission denied
  - [ ] Verify themed permission dialog appears
  - [ ] Verify "Grant Access" and "Not Now" buttons work
  - [ ] Verify guidance to system settings for permanently denied

### Expected Results:
- Files are copied to app-private storage
- No additional permission required for cached files
- Themed permission dialog works correctly
- Graceful handling of denied permissions

---

## 4. API Key Not Persisting to Settings

### Tests:
- [ ] **API Key Storage**
  - [ ] Enter API key in AI Generate screen
  - [ ] Navigate to Settings → API Configuration
  - [ ] Verify API key shows as "Configured"
  - [ ] Verify masked API key is displayed (e.g., `gsk_****abcd`)

- [ ] **API Key Sync**
  - [ ] Update API key in Settings
  - [ ] Return to AI Generate screen
  - [ ] Verify new key is active
  - [ ] Verify no manual refresh needed

- [ ] **API Key Management**
  - [ ] Test "Update Key" functionality
  - [ ] Test "Remove Key" functionality
  - [ ] Verify confirmation dialog for key removal
  - [ ] Verify AI features are disabled after key removal

### Expected Results:
- Single source of truth for API key storage
- Key persists across app restarts
- Masked display in UI
- Sync between AI screen and Settings

---

## 5. Authorized Daily Quota Management

### Tests:
- [ ] **Authorization Setup**
  - [ ] Navigate to Settings → AI Usage → Authorized Controls
  - [ ] Set authorization password
  - [ ] Verify password is hashed and stored securely
  - [ ] Verify authorization status shows as "Enabled"

- [ ] **Quota Modifications**
  - [ ] Test "Increase Quota" with valid password
  - [ ] Test "Decrease Quota" with valid password
  - [ ] Test "Reset Today's Usage" with valid password
  - [ ] Test "Set Custom Limit" with valid password
  - [ ] Test "Restore Default" with valid password

- [ ] **Authorization Security**
  - [ ] Test quota modification with wrong password
  - [ ] Verify error message is shown
  - [ ] Verify no quota change occurs
  - [ ] Test authorization disable functionality

- [ ] **Audit Trail**
  - [ ] Verify last modification timestamp is displayed
  - [ ] Verify timestamp updates after each modification

### Expected Results:
- Password protection works correctly
- All quota modifications require authorization
- Audit trail shows modification history
- Wrong password shows error without changes

---

## 6. Routing & Navigation Audit

### Tests:
- [ ] **Tab Navigation**
  - [ ] Test all tab routes (Study, Library, AI, Progress)
  - [ ] Verify bottom navigation works correctly
  - [ ] Verify state preservation per tab
  - [ ] Verify no duplicate routes exist

- [ ] **Settings Navigation**
  - [ ] Test settings button in AppBar
  - [ ] Verify settings screen opens correctly
  - [ ] Verify back navigation returns to previous tab
  - [ ] Test all settings sub-screens

- [ ] **Deep Link Safety**
  - [ ] Test deep links to various screens
  - [ ] Verify navigation handles invalid routes
  - [ ] Verify error screens show correctly

- [ ] **Dialog and Bottom Sheet Management**
  - [ ] Verify dialogs close before route pop
  - [ ] Verify bottom sheets close before navigation
  - [ ] Test back navigation with open dialogs

### Expected Results:
- All tab routes work correctly
- Settings accessible from AppBar
- State preserved per tab
- No navigation conflicts or duplicate routes

---

## 7. DOCX Import Support

### Tests:
- [ ] **DOCX File Import**
  - [ ] Click "DOCX" import card in AI Generate screen
  - [ ] Select a valid .docx file
  - [ ] Verify file is copied to app storage
  - [ ] Verify text extraction works
  - [ ] Verify extracted text is displayed correctly

- [ ] **DOCX Text Extraction**
  - [ ] Test with simple DOCX file
  - [ ] Test with complex DOCX file (tables, formatting)
  - [ ] Verify paragraphs are extracted
  - [ ] Verify table content is extracted
  - [ ] Verify text is cleaned and normalized

- [ ] **Error Handling**
  - [ ] Test with corrupted DOCX file
  - [ ] Test with password-protected DOCX
  - [ ] Verify friendly error messages
  - [ ] Verify retry functionality

### Expected Results:
- DOCX files can be imported
- Text extraction works correctly
- Tables and paragraphs are extracted
- Graceful error handling for unsupported files

---

## 8. Unified Document Import Flow

### Tests:
- [ ] **Import Pipeline**
  - [ ] Test import for PDF
  - [ ] Test import for TXT
  - [ ] Test import for DOCX
  - [ ] Verify all file types use same pipeline

- [ ] **Caching Flow**
  - [ ] Verify files are cached after import
  - [ ] Verify cache metadata is stored correctly
  - [ ] Verify cached files can be retrieved
  - [ ] Verify cache cleanup works

- [ ] **Unified Preview**
  - [ ] Verify preview screen works for all file types
  - [ ] Verify scope selection works uniformly
  - [ ] Verify text preview displays correctly

### Expected Results:
- Single import pipeline for all file types
- Consistent caching behavior
- Unified preview experience
- Proper scope selection for all types

---

## 9. Error Handling & UX Improvements

### Tests:
- [ ] **Global Error Snackbar**
  - [ ] Test network error handling
  - [ ] Test permission error handling
  - [ ] Test quota exceeded error
  - [ ] Verify retry buttons work

- [ ] **Friendly Error Messages**
  - [ ] Test invalid API key error
  - [ ] Test unsupported model error
  - [ ] Test corrupted document error
  - [ ] Test network timeout error

- [ ] **Loading States**
  - [ ] Verify loading skeletons appear
  - [ ] Verify loading spinners during operations
  - [ ] Verify loading state during AI initialization

- [ ] **Empty States**
  - [ ] Test empty deck list
  - [ ] Test empty analytics
  - [ ] Test empty document cache
  - [ ] Verify friendly empty state messages

- [ ] **Offline Detection**
  - [ ] Test app behavior without internet
  - [ ] Verify offline banner appears
  - [ ] Verify appropriate error messages
  - [ ] Verify retry functionality when online

### Expected Results:
- Consistent error handling across app
- User-friendly error messages
- Proper loading and empty states
- Offline detection and handling

---

## 10. Integration Testing

### Tests:
- [ ] **Complete AI Workflow**
  - [ ] Import document → Extract text → Generate questions → Save to deck
  - [ ] Verify entire workflow works without errors
  - [ ] Test with each file type (PDF, TXT, DOCX)

- [ ] **Settings Changes Impact**
  - [ ] Change API key → Verify AI generation works
  - [ ] Change model → Verify AI generation uses new model
  - [ ] Modify quota → Verify quota enforcement works

- [ ] **Cross-Feature Integration**
  - [ ] Generate questions → Study in Study mode → Check analytics
  - [ ] Verify data flows correctly between features
  - [ ] Verify analytics reflect study activity

### Expected Results:
- Complete workflows work end-to-end
- Settings changes propagate correctly
- Features integrate seamlessly

---

## Performance Testing

### Tests:
- [ ] **Large File Import**
  - [ ] Test with large PDF (>10MB)
  - [ ] Test with large DOCX (>10MB)
  - [ ] Verify app remains responsive
  - [ ] Verify memory usage is reasonable

- [ ] **Large Dataset Analytics**
  - [ ] Test with many decks (>50)
  - [ ] Test with many flashcards (>1000)
  - [ ] Verify analytics load quickly
  - [ ] Verify charts render smoothly

### Expected Results:
- App handles large files gracefully
- Analytics perform well with large datasets
- No memory leaks or performance degradation

---

## Security Testing

### Tests:
- [ ] **API Key Security**
  - [ ] Verify API key is stored securely
  - [ ] Verify API key is not exposed in logs
  - [ ] Verify API key is masked in UI

- [ ] **Authorization Password Security**
  - [ ] Verify password is hashed
  - [ ] Verify password is not exposed in UI
  - [ ] Verify wrong password attempts are handled

### Expected Results:
- Sensitive data is properly secured
- No exposure of credentials in logs/UI
- Proper authentication for sensitive operations

---

## Regression Testing

### Tests:
- [ ] **Existing Functionality**
  - [ ] Test existing deck creation/editing
  - [ ] Test existing flashcard creation/editing
  - [ ] Test existing study modes
  - [ ] Test existing export/backup features

- [ ] **Backward Compatibility**
  - [ ] Test with existing database
  - [ ] Verify data migration works
  - [ ] Verify no data loss occurs

### Expected Results:
- All existing features continue to work
- No regressions introduced
- Data integrity maintained

---

## Test Execution Notes

### Prerequisites:
1. Clean app install (no previous data)
2. Valid Groq API key for testing
3. Sample PDF, TXT, and DOCX files for testing
4. Test device/emulator with proper permissions

### Test Environment:
- [ ] Android testing
- [ ] iOS testing (if applicable)
- [ ] Different screen sizes
- [ ] Different OS versions

### Known Limitations:
- PDF extraction is temporarily disabled (needs compatible library)
- Some advanced DOCX features may not be supported
- Network-dependent features require internet connection

---

## Sign-Off

### Tester: _________________ Date: _________________

### Results:
- [ ] All tests passed
- [ ] Some tests failed (see notes)
- [ ] Critical issues found (see notes)

### Notes:
___________________________________________________________________________
___________________________________________________________________________
___________________________________________________________________________